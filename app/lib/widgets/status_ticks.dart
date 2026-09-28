import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Clock while sending, one grey tick when stored on the server, two grey when delivered, two blue when read.
class StatusTicks extends StatelessWidget {
  const StatusTicks({super.key, required this.status, this.size = 16});

  final MessageStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => Icon(Icons.access_time, size: size - 2, color: AppColors.muted),
      MessageStatus.sent => Icon(Icons.done, size: size, color: AppColors.muted),
      MessageStatus.delivered => Icon(Icons.done_all, size: size, color: AppColors.muted),
      MessageStatus.read => Icon(Icons.done_all, size: size, color: AppColors.tickRead),
      MessageStatus.failed => Icon(Icons.error_outline, size: size, color: Colors.red),
    };
  }
}
