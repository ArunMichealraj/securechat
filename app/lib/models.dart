DateTime? parseDate(dynamic value) => value == null ? null : DateTime.parse(value as String).toLocal();

class AppUser {
  AppUser({required this.id, required this.phone, this.name = '', this.about = '', this.lastSeenAt});

  final String id;
  final String phone;
  String name;
  String about;
  DateTime? lastSeenAt;

  String get displayName => name.isNotEmpty ? name : phone;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        name: (json['name'] ?? '') as String,
        about: (json['about'] ?? '') as String,
        lastSeenAt: parseDate(json['lastSeenAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'about': about,
        'lastSeenAt': lastSeenAt?.toUtc().toIso8601String(),
      };
}

enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  ChatMessage({
    this.id,
    required this.clientId,
    required this.senderId,
    required this.recipientId,
    this.type = 'text',
    required this.body,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
  });

  /// Null until the server has stored the message.
  String? id;
  final String clientId;
  final String senderId;
  final String recipientId;
  final String type;
  final String body;
  DateTime createdAt;
  DateTime? deliveredAt;
  DateTime? readAt;
  bool failed = false;

  MessageStatus get status {
    if (id == null) return failed ? MessageStatus.failed : MessageStatus.sending;
    if (readAt != null) return MessageStatus.read;
    if (deliveredAt != null) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  String peerOf(String myId) => senderId == myId ? recipientId : senderId;

  /// Copies server-side fields onto a locally created message.
  void applyServer(ChatMessage server) {
    id = server.id;
    createdAt = server.createdAt;
    deliveredAt = server.deliveredAt ?? deliveredAt;
    readAt = server.readAt ?? readAt;
    failed = false;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        senderId: json['senderId'] as String,
        recipientId: json['recipientId'] as String,
        type: (json['type'] ?? 'text') as String,
        body: json['body'] as String,
        createdAt: parseDate(json['createdAt'])!,
        deliveredAt: parseDate(json['deliveredAt']),
        readAt: parseDate(json['readAt']),
      );
}

class ChatSummary {
  ChatSummary({required this.peer, required this.lastMessage, this.unread = 0});

  final AppUser peer;
  ChatMessage lastMessage;
  int unread;
}

class Presence {
  const Presence({required this.online, this.lastSeenAt});

  final bool online;
  final DateTime? lastSeenAt;

  factory Presence.fromJson(Map<String, dynamic> json) =>
      Presence(online: json['online'] == true, lastSeenAt: parseDate(json['lastSeenAt']));
}
