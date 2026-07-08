import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/price_list_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  final List<Order> orders;
  final void Function(String orderId, OrderStatus status) onStatusChange;
  final void Function(String orderId, double price) onSetPrice;
  final void Function(String orderId, String field) onTogglePayment;
  final void Function(String orderId, int days) onSetEstimatedDays;

  const AdminDashboardScreen({
    super.key,
    required this.orders,
    required this.onStatusChange,
    required this.onSetPrice,
    required this.onTogglePayment,
    required this.onSetEstimatedDays,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _filter; // null = الكل
  String _query = '';

  static const _tabs = <String?, String>{
    null: 'الكل',
    'pending': 'قيد المراجعة',
    'making': 'قيد التصنيع',
    'done': 'تم التسليم',
    'rejected': 'مرفوض',
  };

  @override
  Widget build(BuildContext context) {
    var filtered = widget.orders.where((o) {
      if (_filter != null && o.status.name != _filter) return false;
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        return o.code.toLowerCase().contains(q) ||
            o.galleryName.toLowerCase().contains(q) ||
            o.customerName.toLowerCase().contains(q);
      }
      return true;
    }).toList();
    filtered = filtered.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'ابحث برقم الطلب أو اسم المعرض أو الزبون',
            prefixIcon: Icon(Icons.search, color: AppColors.textFaint),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _tabs.entries.map((entry) {
              final active = _filter == entry.key;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: active,
                  onSelected: (_) => setState(() => _filter = entry.key),
                  selectedColor: AppColors.teal.withOpacity(0.15),
                  backgroundColor: Colors.transparent,
                  labelStyle: TextStyle(
                    color: active ? AppColors.teal : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(color: active ? AppColors.teal : AppColors.border),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        const PriceListWidget(),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          const EmptyState(text: 'لا توجد طلبات مطابقة')
        else
          ...filtered.map(
            (o) => OrderCard(
              order: o,
              admin: true,
              onStatusChange: (s) => widget.onStatusChange(o.id, s),
              onSetPrice: (p) => widget.onSetPrice(o.id, p),
              onTogglePayment: (f) => widget.onTogglePayment(o.id, f),
              onSetEstimatedDays: (d) => widget.onSetEstimatedDays(o.id, d),
            ),
          ),
      ],
    );
  }
}
