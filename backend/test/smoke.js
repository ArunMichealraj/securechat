// End-to-end check against a running server: two users log in and chat.
// Usage: npm run smoke   (server must be running; override with SERVER=http://host:3000)
const { io } = require('socket.io-client');

const SERVER = process.env.SERVER ?? 'http://localhost:3000';
const suffix = String(Date.now()).slice(-6);

async function api(path, { method = 'GET', token, body } = {}) {
  const res = await fetch(SERVER + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    body: body && JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${JSON.stringify(json)}`);
  return json;
}

async function login(phone, name) {
  const { devCode } = await api('/auth/request-otp', { method: 'POST', body: { phone } });
  const { token, user } = await api('/auth/verify-otp', { method: 'POST', body: { phone, code: devCode } });
  await api('/users/me', { method: 'PATCH', token, body: { name } });
  return { token, user };
}

const connect = (token) =>
  new Promise((resolve, reject) => {
    const s = io(SERVER, { auth: { token }, transports: ['websocket'] });
    s.on('connect', () => resolve(s));
    s.on('connect_error', reject);
  });

const next = (socket, event) => new Promise((resolve) => socket.once(event, resolve));

function check(cond, label) {
  if (!cond) throw new Error('FAILED: ' + label);
  console.log('  ok  ' + label);
}

(async () => {
  const alice = await login(`+91900${suffix}1`, 'Alice');
  const bob = await login(`+91900${suffix}2`, 'Bob');
  check(alice.user.id && bob.user.id, 'two users logged in with OTP');

  const found = await api('/users/lookup', { method: 'POST', token: alice.token, body: { phones: [bob.user.phone] } });
  check(found[0]?.id === bob.user.id, 'alice finds bob by phone number');

  const a = await connect(alice.token);
  const b = await connect(bob.token);

  const presence = await a.emitWithAck('presence:watch', { userId: bob.user.id });
  check(presence.online === true, 'alice sees bob online');

  const incoming = next(b, 'message:new');
  const ack = await a.emitWithAck('message:send', { clientId: 'c1', to: bob.user.id, type: 'text', body: 'Hi Bob!' });
  check(ack.ok && ack.message.id, 'server acked alice message');
  const got = await incoming;
  check(got.body === 'Hi Bob!' && got.senderId === alice.user.id, 'bob received message in real time');

  const typing = next(b, 'typing');
  a.emit('typing', { to: bob.user.id, isTyping: true });
  check((await typing).from === alice.user.id, 'bob sees alice typing');

  let status = next(a, 'message:status');
  b.emit('message:delivered', { ids: [got.id] });
  check((await status).status === 'delivered', 'alice gets delivered tick');

  status = next(a, 'message:status');
  b.emit('message:read', { peerId: alice.user.id });
  check((await status).status === 'read', 'alice gets read (blue) tick');

  // Offline delivery: bob disconnects, alice sends, bob reconnects and receives it.
  const wentOffline = next(a, 'presence');
  b.disconnect();
  check((await wentOffline).online === false, 'alice sees bob go offline with last seen');
  await a.emitWithAck('message:send', { clientId: 'c2', to: bob.user.id, type: 'text', body: 'You there?' });
  const b2 = io(SERVER, { auth: { token: bob.token }, transports: ['websocket'] });
  const queued = await next(b2, 'message:new');
  check(queued.body === 'You there?', 'bob receives queued message after reconnecting');

  const chats = await api('/chats', { token: bob.token });
  check(chats[0]?.peer.id === alice.user.id && chats[0].unread === 1, 'bob chat list shows alice with 1 unread');

  const history = await api(`/chats/${alice.user.id}/messages`, { token: bob.token });
  check(history.length === 2 && history[0].body === 'Hi Bob!', 'history returns both messages in order');

  const bad = io(SERVER, { auth: { token: 'nope' }, transports: ['websocket'], reconnection: false });
  const kicked = await new Promise((r) => bad.on('disconnect', () => r(true)));
  check(kicked, 'socket with invalid token is rejected');

  console.log('\nAll smoke tests passed');
  process.exit(0);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
