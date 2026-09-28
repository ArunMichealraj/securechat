import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'status_ticks.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine, this.onRetry});

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: EdgeInsets.only(left: isMine ? 48 : 8, right: isMine ? 8 : 48, top: 2, bottom: 2),
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        color: isMine ? AppColors.bubbleMine : AppColors.bubbleTheirs,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
          bottomLeft: Radius.circular(isMine ? 10 : 2),
          bottomRight: Radius.circular(isMine ? 2 : 10),
        ),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 1))],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Text(message.body, style: const TextStyle(fontSize: 15.5, height: 1.3)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatClock(message.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              if (isMine) ...[const SizedBox(width: 3), StatusTicks(status: message.status)],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: message.status == MessageStatus.failed
          ? GestureDetector(
              onTap: onRetry,
              child: Tooltip(message: 'Not sent. Tap to retry.', child: bubble),
            )
          : bubble,
    );
  }
}
