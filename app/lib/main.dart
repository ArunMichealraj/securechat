import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/chats_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const AbChatApp(),
    ),
  );
}

class AbChatApp extends StatelessWidget {
  const AbChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<AppState, Phase>((s) => s.phase);
    return MaterialApp(
      title: 'AB Chat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Changing the key resets the navigator, so logging in/out never leaves stale screens behind.
      home: KeyedSubtree(
        key: ValueKey(phase),
        child: switch (phase) {
          Phase.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
          Phase.loggedOut => const LoginScreen(),
          Phase.needsProfile => const ProfileScreen(isSetup: true),
          Phase.ready => const ChatsScreen(),
        },
      ),
    );
  }
}
