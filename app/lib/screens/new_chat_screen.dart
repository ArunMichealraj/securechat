import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _phone = TextEditingController(text: '+91');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final state = context.read<AppState>();
    final phone = _phone.text.replaceAll(' ', '');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await state.findUserByPhone(phone);
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = '$phone is not on SecureChat yet. Ask them to install the app.');
      } else if (user.id == state.me!.id) {
        setState(() => _error = 'That\'s your own number.');
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(peer: user)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AppState>().me!;
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Their phone number',
              helperText: 'Include country code, e.g. +919876543210',
              prefixIcon: Icon(Icons.person_search),
            ),
            onSubmitted: (_) => _start(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _start, child: const Text('Start chat')),
          const SizedBox(height: 24),
          Text('Your number: ${me.phone}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
