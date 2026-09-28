import 'package:flutter_test/flutter_test.dart';
import 'package:secure_chat/format.dart';
import 'package:secure_chat/models.dart';

void main() {
  ChatMessage message() => ChatMessage(
        clientId: 'c1',
        senderId: 'me',
        recipientId: 'you',
        body: 'hi',
        createdAt: DateTime(2026, 9, 28, 10),
      );

  test('message status follows server acks', () {
    final m = message();
    expect(m.status, MessageStatus.sending);
    m.failed = true;
    expect(m.status, MessageStatus.failed);
    m.applyServer(message()..id = 'server-id');
    expect(m.status, MessageStatus.sent);
    m.deliveredAt = DateTime.now();
    expect(m.status, MessageStatus.delivered);
    m.readAt = DateTime.now();
    expect(m.status, MessageStatus.read);
  });

  test('chat list time format', () {
    final now = DateTime(2026, 9, 28, 18);
    expect(formatChatTime(DateTime(2026, 9, 27, 9), now: now), 'Yesterday');
    expect(formatChatTime(DateTime(2026, 9, 1, 9), now: now), '01/09/26');
  });
}
