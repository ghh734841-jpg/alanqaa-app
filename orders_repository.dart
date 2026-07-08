import 'package:cloud_firestore/cloud_firestore.dart' as firebase_custom;
import '../models/order.dart';

/// مستودع الطلبات — يقرأ ويكتب مباشرة إلى Firestore بحيث تكون الطلبات
/// مشتركة وفورية بين كل الأجهزة (عميل أو مدير) بدل التخزين المحلي.
class OrdersRepository {
  // تم استخدام اسم الكود المخصص لتفادي تعارض الـ Order تماماً
  final _col = firebase_custom.FirebaseFirestore.instance.collection('orders');

  /// تدفّق حي بكل الطلبات (يُستخدم في لوحة تحكم المدير)، مرتّب بالأحدث أولاً.
  Stream<List<Order>> watchAllOrders() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => Order.fromMap(d.id, d.data())).toList(),
        );
  }

  /// تدفّق حي بطلبات عميل واحد فقط (حسب رقم جواله) — تُستخدم في شاشة "طلباتي".
  Stream<List<Order>> watchMyOrders(String phone) {
    return _col
        .where('customerPhone', isEqualTo: phone)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Order.fromMap(d.id, d.data())).toList());
  }

  /// إنشاء طلب جديد، ويُعيد رقم الطلب المُولَّد (GDC-N) بعد الحفظ.
  Future<void> addOrder(Order order) async {
    await _col.doc(order.id).set(order.toMap());
  }

  /// يحسب رقم الطلب التالي (GDC-N) بالاعتماد على عدد الطلبات الحالية.
  Future<int> getOrderCount() async {
    final agg = await _col.count().get();
    return agg.count ?? 0;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) =>
      _col.doc(orderId).update({'status': status.name});

  Future<void> setPrice(String orderId, double price) =>
      _col.doc(orderId).update({'price': price, 'priceSet': true});

  Future<void> setEstimatedDays(String orderId, int days) =>
      _col.doc(orderId).update({'estimatedDays': days});

  Future<void> togglePayment(String orderId, String field, bool value) =>
      _col.doc(orderId).update({field: value});
}
