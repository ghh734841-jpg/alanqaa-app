import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  IconData get _icon {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.making:
        return Icons.build_outlined;
      case OrderStatus.done:
        return Icons.local_shipping_outlined;
      case OrderStatus.rejected:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
