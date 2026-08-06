import 'package:flutter/material.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'CONFIRMED' => const Color(0xFF006C67),
      'ACTIVE' => const Color(0xFF3E6EA8),
      'COMPLETED' => const Color(0xFF52616B),
      'CANCELLED' => const Color(0xFFC33C3C),
      _ => const Color(0xFFE9A23B),
    };

    return Chip(
      label: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.18)),
      visualDensity: VisualDensity.compact,
    );
  }
}
