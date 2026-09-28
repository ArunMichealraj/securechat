import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/status_ticks.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chats = state.chats;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SecureChat'),
            if (!state.connected) const Text('Connecting…', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'logout') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) context.read<AppState>().logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadChats,
        child: chats.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet.\nTap the button below to start one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, i) => _ChatTile(chat: chats[i], myId: state.me!.id),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New chat',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewChatScreen())),
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat, required this.myId});

  final ChatSummary chat;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final last = chat.lastMessage;
    final typing = state.isTyping(chat.peer.id);
    final hasUnread = chat.unread > 0;

    return ListTile(
      leading: Avatar(user: chat.peer),
      title: Text(chat.peer.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: typing
          ? const Text('typing…', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500))
          : Row(
              children: [
                if (last.senderId == myId) ...[StatusTicks(status: last.status), const SizedBox(width: 4)],
                Expanded(child: Text(last.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatChatTime(last.createdAt),
            style: TextStyle(fontSize: 12, color: hasUnread ? AppColors.accent : AppColors.muted),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
              child: Text('${chat.unread}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          else
            const SizedBox(height: 18),
        ],
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(peer: chat.peer))),
    );
  }
}
