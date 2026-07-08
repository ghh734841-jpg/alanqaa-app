import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

/// خدمة تخزين الطلبات محليًا على الجهاز باستخدام SharedPreferences.
///
/// ملاحظة: هذا تخزين محلي (على كل جهاز على حدة). لو احتجت أن تتشارك
/// الشركة والعملاء نفس قائمة الطلبات من عدة أجهزة، استبدل هذه الخدمة
/// بخدمة تعتمد على قاعدة بيانات سحابية (Firebase / Supabase / REST API).
class StorageService {
  static const _ordersKey = 'gdc_orders_v1';

  Future<List<Order>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Order.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersKey, Order.encodeList(orders));
  }
}
