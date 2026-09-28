import 'package:flutter/foundation.dart';

/// Server the login screen suggests. On a real phone this must be your PC's
/// Wi-Fi IP (phone and PC on the same network). It can be changed on the login screen.
String get defaultServerUrl => kIsWeb ? 'http://localhost:3000' : 'http://192.168.0.113:3000';
