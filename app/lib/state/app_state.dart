import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/session_store.dart';

enum Phase { loading, loggedOut, needsProfile, ready }

Map<String, dynamic> _asMap(dynamic data) => Map<String, dynamic>.from(data as Map);

/// Holds the session, the socket connection and all chats/messages in memory.
class AppState extends ChangeNotifier {
  final _store = SessionStore();
  final _uuid = const Uuid();

  Phase phase = Phase.loading;
  String serverUrl = defaultServerUrl;
  String? _token;
  AppUser? me;

  io.Socket? _socket;
  bool connected = false;

  final Map<String, AppUser> _users = {};
  final Map<String, ChatSummary> _chats = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatMessage> _byId = {};
  final Set<String> _historyLoaded = {};
  final Set<String> _inFlight = {};
  final Map<String, Timer> _typingTimers = {};
  final Map<String, Presence> _presence = {};
  String? openPeerId;

  Api get api => Api(serverUrl, token: _token);

  List<ChatSummary> get chats =>
      _chats.values.toList()..sort((a, b) => b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt));
  List<ChatMessage> messagesWith(String peerId) => _messages[peerId] ?? const [];
  bool isTyping(String peerId) => _typingTimers.containsKey(peerId);
  Presence? presenceOf(String peerId) => _presence[peerId];

  // ---------------------------------------------------------------- session

  Future<void> init() async {
    final stored = await _store.load();
    if (stored.serverUrl != null) serverUrl = stored.serverUrl!;
    _token = stored.token;
    me = stored.user;
    if (_token == null) {
      phase = Phase.loggedOut;
      notifyListeners();
      return;
    }
    try {
      me = AppUser.fromJson(_asMap(await api.get('/users/me')));
      await _store.saveUser(me!);
    } on ApiException catch (e) {
      // 401: token expired or server data reset. Otherwise we're offline and use the cached profile.
      if (e.status == 401) return logout();
    }
    if (me == null) return logout();
    _enterApp();
  }

  void _enterApp() {
    phase = me!.name.isEmpty ? Phase.needsProfile : Phase.ready;
    notifyListeners();
    if (phase == Phase.ready) {
      _connect();
      loadChats();
    }
  }

  /// Returns the code when the server runs in development mode (no SMS provider yet).
  Future<String?> requestOtp(String server, String phone) async {
    serverUrl = Api.normalizeBaseUrl(server);
    final res = _asMap(await api.post('/auth/request-otp', {'phone': phone}));
    await _store.saveServerUrl(serverUrl);
    return res['devCode'] as String?;
  }

  Future<void> verifyOtp(String phone, String code) async {
    final res = _asMap(await api.post('/auth/verify-otp', {'phone': phone, 'code': code}));
    _token = res['token'] as String;
    me = AppUser.fromJson(_asMap(res['user']));
    await _store.saveSession(_token!, me!);
    _enterApp();
  }

  Future<void> saveProfile(String name, String about) async {
    me = AppUser.fromJson(_asMap(await api.patch('/users/me', {'name': name, 'about': about})));
    await _store.saveUser(me!);
    if (phase == Phase.needsProfile) {
      _enterApp();
    } else {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _socket?.dispose();
    _socket = null;
    connected = false;
    _token = null;
    me = null;
    openPeerId = null;
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    _users.clear();
    _chats.clear();
    _messages.clear();
    _byId.clear();
    _historyLoaded.clear();
    _inFlight.clear();
    _presence.clear();
    await _store.clearSession();
    phase = Phase.loggedOut;
    notifyListeners();
  }

  // ---------------------------------------------------------------- socket

  void _connect() {
    _socket?.dispose();
    final socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) {
      connected = true;
      notifyListeners();
      _resendPending();
      loadChats();
      if (openPeerId != null) _afterOpen(openPeerId!);
    });
    socket.onDisconnect((_) {
      connected = false;
      _inFlight.clear(); // acks for these will never arrive; they are resent on reconnect
      notifyListeners();
    });
    socket.on('auth_error', (_) => logout());
    socket.on('message:new', (data) => _onIncoming(ChatMessage.fromJson(_asMap(data))));
    socket.on('message:status', (data) => _onStatus(_asMap(data)));
    socket.on('typing', (data) => _onTyping(_asMap(data)));
    socket.on('presence', (data) {
      final map = _asMap(data);
      _presence[map['userId'] as String] = Presence.fromJson(map);
      notifyListeners();
    });

    socket.connect();
    _socket = socket;
  }

  Future<void> _onIncoming(ChatMessage message) async {
    _socket?.emit('message:delivered', {
      'ids': [message.id],
    });
    if (_byId.containsKey(message.id)) return; // already have it

    final peerId = message.senderId;
    final isOpen = openPeerId == peerId;
    _addToThread(peerId, message);
    if (isOpen) _socket?.emit('message:read', {'peerId': peerId});
    _clearTyping(peerId);
    await _updateChat(peerId, message, unreadDelta: isOpen ? 0 : 1);
    notifyListeners();
  }

  void _onStatus(Map<String, dynamic> data) {
    final at = parseDate(data['at']) ?? DateTime.now();
    final isRead = data['status'] == 'read';
    for (final id in (data['ids'] as List).cast<String>()) {
      final m = _byId[id];
      if (m == null) continue;
      m.deliveredAt ??= at;
      if (isRead) m.readAt ??= at;
    }
    notifyListeners();
  }

  void _onTyping(Map<String, dynamic> data) {
    final from = data['from'] as String;
    _typingTimers.remove(from)?.cancel();
    if (data['isTyping'] == true) {
      // Auto-expire in case the "stopped typing" event is lost.
      _typingTimers[from] = Timer(const Duration(seconds: 6), () {
        _typingTimers.remove(from);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _clearTyping(String peerId) => _typingTimers.remove(peerId)?.cancel();

  // ---------------------------------------------------------------- chats & messages

  Future<void> loadChats() async {
    try {
      final list = (await api.get('/chats')) as List;
      for (final raw in list) {
        final json = _asMap(raw);
        final peer = AppUser.fromJson(_asMap(json['peer']));
        _users[peer.id] = peer;
        final last = _mergeFromServer(peer.id, [ChatMessage.fromJson(_asMap(json['lastMessage']))]).first;
        _chats[peer.id] = ChatSummary(
          peer: peer,
          lastMessage: last,
          unread: openPeerId == peer.id ? 0 : json['unread'] as int,
        );
      }
      notifyListeners();
    } on ApiException {
      // Offline: keep what we have.
    }
  }

  Future<void> openChat(AppUser peer) async {
    _users[peer.id] = peer;
    openPeerId = peer.id;
    _chats[peer.id]?.unread = 0;
    notifyListeners();
    _afterOpen(peer.id);
    if (!_historyLoaded.contains(peer.id)) {
      try {
        final list = (await api.get('/chats/${peer.id}/messages?limit=100')) as List;
        _mergeFromServer(peer.id, list.map((m) => ChatMessage.fromJson(_asMap(m))).toList());
        _historyLoaded.add(peer.id);
        notifyListeners();
      } on ApiException {
        // Offline: show what's cached.
      }
    }
  }

  void closeChat(String peerId) {
    if (openPeerId == peerId) openPeerId = null;
  }

  void _afterOpen(String peerId) {
    if (!connected) return;
    _socket!.emit('message:read', {'peerId': peerId});
    _socket!.emitWithAckAsync('presence:watch', {'userId': peerId}).then((res) {
      _presence[peerId] = Presence.fromJson(_asMap(res));
      notifyListeners();
    });
  }

  void sendText(String peerId, String text) {
    final message = ChatMessage(
      clientId: _uuid.v4(),
      senderId: me!.id,
      recipientId: peerId,
      body: text,
      createdAt: DateTime.now(),
    );
    _addToThread(peerId, message);
    _updateChat(peerId, message);
    notifyListeners();
    _deliver(message);
  }

  void retry(ChatMessage message) {
    message.failed = false;
    notifyListeners();
    _deliver(message);
  }

  void sendTyping(String peerId, bool isTyping) {
    if (connected) _socket!.emit('typing', {'to': peerId, 'isTyping': isTyping});
  }

  /// Finds a registered user by phone number, or null if they haven't joined.
  Future<AppUser?> findUserByPhone(String phone) async {
    final list = (await api.post('/users/lookup', {
      'phones': [phone],
    })) as List;
    if (list.isEmpty) return null;
    final user = AppUser.fromJson(_asMap(list.first));
    _users[user.id] = user;
    return user;
  }

  Future<void> _deliver(ChatMessage message) async {
    // Not connected: stays "sending" and goes out from _resendPending() on reconnect.
    if (!connected || !_inFlight.add(message.clientId)) return;
    try {
      final res = _asMap(await _socket!.emitWithAckAsync('message:send', {
        'clientId': message.clientId,
        'to': message.recipientId,
        'type': message.type,
        'body': message.body,
      }));
      if (res['ok'] == true) {
        message.applyServer(ChatMessage.fromJson(_asMap(res['message'])));
        _byId[message.id!] = message;
      } else {
        message.failed = true;
        debugPrint('Send failed: ${res['error']}');
      }
    } finally {
      _inFlight.remove(message.clientId);
      notifyListeners();
    }
  }

  void _resendPending() {
    for (final thread in _messages.values) {
      for (final m in thread) {
        if (m.id == null && !m.failed) _deliver(m);
      }
    }
  }

  void _addToThread(String peerId, ChatMessage message) {
    final thread = _messages.putIfAbsent(peerId, () => []);
    thread.add(message);
    if (thread.length > 1 && thread[thread.length - 2].createdAt.isAfter(message.createdAt)) {
      thread.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    if (message.id != null) _byId[message.id!] = message;
  }

  /// Merges server messages into the local thread without duplicating ones we already have.
  /// Returns the local instance for each server message.
  List<ChatMessage> _mergeFromServer(String peerId, List<ChatMessage> fetched) {
    final thread = _messages.putIfAbsent(peerId, () => []);
    final result = <ChatMessage>[];
    for (final server in fetched) {
      var local = _byId[server.id] ??
          thread.where((m) => m.id == null && m.clientId == server.clientId && m.senderId == server.senderId).firstOrNull;
      if (local != null) {
        local.applyServer(server);
        if (!thread.contains(local)) thread.add(local);
      } else {
        local = server;
        thread.add(server);
      }
      _byId[local.id!] = local;
      result.add(local);
    }
    thread.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Future<void> _updateChat(String peerId, ChatMessage message, {int unreadDelta = 0}) async {
    final existing = _chats[peerId];
    if (existing != null) {
      if (!message.createdAt.isBefore(existing.lastMessage.createdAt)) existing.lastMessage = message;
      existing.unread += unreadDelta;
      return;
    }
    var peer = _users[peerId];
    if (peer == null) {
      try {
        peer = AppUser.fromJson(_asMap(await api.get('/users/$peerId')));
        _users[peerId] = peer;
      } on ApiException {
        return;
      }
    }
    _chats[peerId] = ChatSummary(peer: peer, lastMessage: message, unread: unreadDelta);
  }

  @override
  void dispose() {
    _socket?.dispose();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
