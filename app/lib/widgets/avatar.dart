import 'package:flutter/material.dart';

import '../models.dart';

const _palette = [
  Color(0xFF00A884),
  Color(0xFF53BDEB),
  Color(0xFFFF8A65),
  Color(0xFFBA68C8),
  Color(0xFF4DB6AC),
  Color(0xFFF06292),
  Color(0xFF7986CB),
  Color(0xFFFFB74D),
];

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.radius = 24});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim();
    final initials = name.isEmpty
        ? null
        : name.split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: _palette[user.id.hashCode.abs() % _palette.length],
      foregroundColor: Colors.white,
      child: initials == null
          ? Icon(Icons.person, size: radius)
          : Text(initials, style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w600)),
    );
  }
}
