import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peer});

  final AppUser peer;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  late final AppState _state = context.read<AppState>();
  Timer? _typingTimer;
  bool _sentTyping = false;

  @override
  void initState() {
    super.initState();
    _state.openChat(widget.peer);
    _input.addListener(() => setState(() {})); // toggles the send button
  }

  @override
  void dispose() {
    _stopTyping();
    _state.closeChat(widget.peer.id);
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (text.isEmpty) return _stopTyping();
    if (!_sentTyping) {
      _sentTyping = true;
      _state.sendTyping(widget.peer.id, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_sentTyping) {
      _sentTyping = false;
      _state.sendTyping(widget.peer.id, false);
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _state.sendText(widget.peer.id, text);
    _input.clear();
    _stopTyping();
  }

  String? _subtitle(AppState state) {
    if (state.isTyping(widget.peer.id)) return 'typing…';
    final presence = state.presenceOf(widget.peer.id);
    if (presence == null) return null;
    if (presence.online) return 'online';
    return presence.lastSeenAt == null ? null : formatLastSeen(presence.lastSeenAt!);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.messagesWith(widget.peer.id);
    final myId = state.me!.id;
    final subtitle = _subtitle(state);

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(user: widget.peer, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.peer.displayName, style: const TextStyle(fontSize: 17), overflow: TextOverflow.ellipsis),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const _EmptyChatHint()
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final index = messages.length - 1 - i;
                      final message = messages[index];
                      final showDay = index == 0 || !isSameDay(messages[index - 1].createdAt, message.createdAt);
                      return Column(
                        children: [
                          if (showDay) _DayChip(date: message.createdAt),
                          MessageBubble(
                            message: message,
                            isMine: message.senderId == myId,
                            onRetry: () => state.retry(message),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _input,
                        onChanged: _onChanged,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FloatingActionButton.small(
                    heroTag: null,
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    onPressed: _input.text.trim().isEmpty ? null : _send,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Text(formatDayHeader(date), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    );
  }
}

class _EmptyChatHint extends StatelessWidget {
  const _EmptyChatHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF3C4), borderRadius: BorderRadius.circular(8)),
        child: const Text(
          'Say hi! 👋\nEnd-to-end encryption is coming in the next step.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
