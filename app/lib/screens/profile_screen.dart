import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

/// Used both right after sign-up (name required) and later from the menu to edit the profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isSetup = false});

  final bool isSetup;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _me = context.read<AppState>().me!;
  late final _name = TextEditingController(text: _me.name);
  late final _about = TextEditingController(text: _me.about);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().saveProfile(_name.text.trim(), _about.text.trim());
      if (mounted && !widget.isSetup) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? 'Profile info' : 'Profile'),
        automaticallyImplyLeading: !widget.isSetup,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.isSetup)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Please provide your name. Your contacts will see it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          Center(child: Avatar(user: _me, radius: 48)),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            maxLength: 50,
            autofocus: widget.isSetup,
            decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _about,
            maxLength: 140,
            decoration: const InputDecoration(labelText: 'About', prefixIcon: Icon(Icons.info_outline)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: Text(_me.phone),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(widget.isSetup ? 'Next' : 'Save'),
          ),
        ],
      ),
    );
  }
}
