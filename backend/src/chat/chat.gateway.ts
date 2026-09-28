import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtPayload } from '../common/jwt-auth.guard';
import { UsersService } from '../users/users.service';
import { ChatService } from './chat.service';
import { MESSAGE_TYPES, Message, MessageType } from './message.entity';

const userRoom = (id: string) => `user:${id}`;
const presenceRoom = (id: string) => `presence:${id}`;
const MAX_BODY = 64 * 1024;

/**
 * Socket.IO events
 *  client -> server
 *    message:send      { clientId, to, type, body }   ack: { ok, message } | { ok: false, error }
 *    message:delivered { ids }
 *    message:read      { peerId }
 *    typing            { to, isTyping }
 *    presence:watch    { userId }                     ack: { online, lastSeenAt }
 *  server -> client
 *    message:new       Message
 *    message:status    { ids, status: 'delivered' | 'read', at }
 *    typing            { from, isTyping }
 *    presence          { userId, online, lastSeenAt }
 */
@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(ChatGateway.name);
  // userId -> number of open sockets. Move to Redis when running more than one server.
  private readonly online = new Map<string, number>();

  constructor(
    private readonly jwt: JwtService,
    private readonly chat: ChatService,
    private readonly users: UsersService,
  ) {}

  async handleConnection(socket: Socket) {
    const userId = this.authenticate(socket);
    if (!userId) {
      socket.emit('auth_error', 'Invalid or missing token');
      socket.disconnect(true);
      return;
    }
    socket.data.userId = userId;
    socket.join(userRoom(userId));

    const count = (this.online.get(userId) ?? 0) + 1;
    this.online.set(userId, count);
    if (count === 1) this.server.to(presenceRoom(userId)).emit('presence', { userId, online: true, lastSeenAt: null });

    for (const message of await this.chat.pendingFor(userId)) socket.emit('message:new', message);
  }

  async handleDisconnect(socket: Socket) {
    const userId: string | undefined = socket.data.userId;
    if (!userId) return;
    const count = (this.online.get(userId) ?? 1) - 1;
    if (count > 0) {
      this.online.set(userId, count);
      return;
    }
    this.online.delete(userId);
    const lastSeenAt = await this.users.touchLastSeen(userId);
    this.server.to(presenceRoom(userId)).emit('presence', { userId, online: false, lastSeenAt });
  }

  @SubscribeMessage('message:send')
  async send(@ConnectedSocket() socket: Socket, @MessageBody() data: { clientId?: string; to?: string; type?: string; body?: string }) {
    const { clientId, to, body } = data ?? {};
    const type = (data?.type ?? 'text') as MessageType;
    if (typeof clientId !== 'string' || typeof to !== 'string' || typeof body !== 'string' || !body.length) {
      return { ok: false, error: 'clientId, to and body are required' };
    }
    if (!MESSAGE_TYPES.includes(type)) return { ok: false, error: 'Invalid type' };
    if (body.length > MAX_BODY) return { ok: false, error: 'Message too large' };

    try {
      const message = await this.chat.send(socket.data.userId, to, type, body, clientId);
      this.server.to(userRoom(to)).emit('message:new', message);
      return { ok: true, message };
    } catch (err) {
      return { ok: false, error: (err as Error).message };
    }
  }

  @SubscribeMessage('message:delivered')
  async delivered(@ConnectedSocket() socket: Socket, @MessageBody() data: { ids?: string[] }) {
    if (!Array.isArray(data?.ids)) return;
    this.notifySenders(await this.chat.markDelivered(socket.data.userId, data.ids.slice(0, 500)), 'delivered');
  }

  @SubscribeMessage('message:read')
  async read(@ConnectedSocket() socket: Socket, @MessageBody() data: { peerId?: string }) {
    if (typeof data?.peerId !== 'string') return;
    this.notifySenders(await this.chat.markRead(socket.data.userId, data.peerId), 'read');
  }

  @SubscribeMessage('typing')
  typing(@ConnectedSocket() socket: Socket, @MessageBody() data: { to?: string; isTyping?: boolean }) {
    if (typeof data?.to !== 'string') return;
    this.server.to(userRoom(data.to)).emit('typing', { from: socket.data.userId, isTyping: !!data.isTyping });
  }

  @SubscribeMessage('presence:watch')
  async watchPresence(@ConnectedSocket() socket: Socket, @MessageBody() data: { userId?: string }) {
    if (typeof data?.userId !== 'string') return { online: false, lastSeenAt: null };
    socket.join(presenceRoom(data.userId));
    if (this.online.has(data.userId)) return { online: true, lastSeenAt: null };
    const user = await this.users.get(data.userId).catch(() => null);
    return { online: false, lastSeenAt: user?.lastSeenAt ?? null };
  }

  private notifySenders(messages: Message[], status: 'delivered' | 'read') {
    const bySender = new Map<string, string[]>();
    for (const m of messages) bySender.set(m.senderId, [...(bySender.get(m.senderId) ?? []), m.id]);
    const at = new Date();
    for (const [senderId, ids] of bySender) this.server.to(userRoom(senderId)).emit('message:status', { ids, status, at });
  }

  private authenticate(socket: Socket): string | null {
    const token = socket.handshake.auth?.token ?? socket.handshake.query?.token;
    if (typeof token !== 'string') return null;
    try {
      return this.jwt.verify<JwtPayload>(token).sub;
    } catch (err) {
      this.logger.debug(`Socket auth failed: ${(err as Error).message}`);
      return null;
    }
  }
}
