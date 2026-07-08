import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class PriceListWidget extends StatefulWidget {
  const PriceListWidget({super.key});

  @override
  State<PriceListWidget> createState() => _PriceListWidgetState();
}

class _PriceListWidgetState extends State<PriceListWidget> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppColors.teal),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'قائمة أسعار الخامات (مرجع)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
                Icon(_open ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < kMaterialPriceList.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: i < kMaterialPriceList.length - 1
                          ? const Border(bottom: BorderSide(color: Color(0xFF232F3F)))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            kMaterialPriceList[i].label,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFFC4CEDB), height: 1.5),
                          ),
                        ),
                        Text(
                          '${kMaterialPriceList[i].price.toStringAsFixed(0)} ريال/م',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
