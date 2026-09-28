import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '+91');
  late final _server = TextEditingController(text: context.read<AppState>().serverUrl);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final phone = _phone.text.replaceAll(' ', '');
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
      setState(() => _error = 'Enter your number with country code, e.g. +919876543210');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final devCode = await context.read<AppState>().requestOtp(_server.text, phone);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone, devCode: devCode),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Center(child: Image.asset('assets/logo.png', width: 112, height: 112)),
            const SizedBox(height: 16),
            Text(
              'Welcome to AB Chat',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your phone number. We will send you a 6-digit code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone)),
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 16),
            // Only developers need to point the app at another server.
            if (kDebugMode)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Server', style: TextStyle(fontSize: 14)),
                subtitle: Text(_server.text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                children: [
                  TextField(
                    controller: _server,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Server address',
                      helperText: 'Leave as is, or a local server e.g. http://192.168.0.113:3000',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _next,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
