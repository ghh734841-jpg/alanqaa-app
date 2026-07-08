import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.grid_view_outlined, size: 30, color: AppColors.textFaint),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
