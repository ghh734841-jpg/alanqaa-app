import 'package:flutter/material.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';

class OrdersListScreen extends StatelessWidget {
  final List<Order> orders;
  const OrdersListScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: EmptyState(text: 'لا توجد طلبات بعد — أضِف طلبك الأول من تبويب «طلب جديد»'),
      );
    }
    final reversed = orders.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: reversed.length,
      itemBuilder: (context, index) => OrderCard(order: reversed[index], admin: false),
    );
  }
}
