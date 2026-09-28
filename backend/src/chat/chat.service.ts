import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, LessThan, Repository } from 'typeorm';
import { UsersService } from '../users/users.service';
import { User } from '../users/user.entity';
import { Message, MessageType } from './message.entity';

export interface ChatSummary {
  peer: User;
  lastMessage: Message;
  unread: number;
}

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Message) private readonly messages: Repository<Message>,
    private readonly users: UsersService,
  ) {}

  async send(senderId: string, recipientId: string, type: MessageType, body: string, clientId: string): Promise<Message> {
    if (senderId === recipientId) throw new BadRequestException('Cannot message yourself');
    await this.users.get(recipientId); // throws if the recipient does not exist
    // Phones resend unacked messages after reconnecting; don't store them twice.
    const duplicate = await this.messages.findOneBy({ senderId, clientId });
    if (duplicate) return duplicate;
    return this.messages.save(this.messages.create({ senderId, recipientId, type, body, clientId }));
  }

  // Messages that arrived while the user was offline.
  pendingFor(userId: string): Promise<Message[]> {
    return this.messages.find({ where: { recipientId: userId, deliveredAt: IsNull() }, order: { createdAt: 'ASC' } });
  }

  /** Marks messages addressed to `userId` as delivered; returns the ones that changed. */
  async markDelivered(userId: string, ids: string[]): Promise<Message[]> {
    if (!ids.length) return [];
    const changed = await this.messages.findBy({ id: In(ids), recipientId: userId, deliveredAt: IsNull() });
    if (!changed.length) return [];
    const now = new Date();
    await this.messages.update({ id: In(changed.map((m) => m.id)) }, { deliveredAt: now });
    for (const m of changed) m.deliveredAt = now;
    return changed;
  }

  /** Marks everything `peerId` sent to `userId` as read; returns the ones that changed. */
  async markRead(userId: string, peerId: string): Promise<Message[]> {
    const changed = await this.messages.findBy({ senderId: peerId, recipientId: userId, readAt: IsNull() });
    if (!changed.length) return [];
    const now = new Date();
    const ids = changed.map((m) => m.id);
    await this.messages.update({ id: In(ids) }, { readAt: now });
    await this.messages.update({ id: In(ids), deliveredAt: IsNull() }, { deliveredAt: now });
    for (const m of changed) {
      m.readAt = now;
      m.deliveredAt ??= now;
    }
    return changed;
  }

  history(userId: string, peerId: string, before?: Date, limit = 50): Promise<Message[]> {
    const createdAt = before ? LessThan(before) : undefined;
    return this.messages
      .find({
        where: [
          { senderId: userId, recipientId: peerId, ...(createdAt && { createdAt }) },
          { senderId: peerId, recipientId: userId, ...(createdAt && { createdAt }) },
        ],
        order: { createdAt: 'DESC' },
        take: Math.min(limit, 100),
      })
      .then((rows) => rows.reverse());
  }

  async chats(userId: string): Promise<ChatSummary[]> {
    const [sentTo, receivedFrom] = await Promise.all([
      this.messages.createQueryBuilder('m').select('DISTINCT m.recipientId', 'peer').where('m.senderId = :userId', { userId }).getRawMany(),
      this.messages.createQueryBuilder('m').select('DISTINCT m.senderId', 'peer').where('m.recipientId = :userId', { userId }).getRawMany(),
    ]);
    const peerIds = [...new Set([...sentTo, ...receivedFrom].map((r) => r.peer as string))];
    const peers = await this.users.findMany(peerIds);

    const summaries = await Promise.all(
      peers.map(async (peer) => {
        const [lastMessage] = await this.history(userId, peer.id, undefined, 1);
        const unread = await this.messages.countBy({ senderId: peer.id, recipientId: userId, readAt: IsNull() });
        return { peer, lastMessage, unread };
      }),
    );
    return summaries.sort((a, b) => new Date(b.lastMessage.createdAt).getTime() - new Date(a.lastMessage.createdAt).getTime());
  }
}
