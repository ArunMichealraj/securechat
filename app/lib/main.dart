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
      // On wide screens (desktop browser) show the app as a centered column instead of stretching it.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFD6DEEA),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 24)],
              ),
              child: child,
            ),
          ),
        ),
      ),
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
