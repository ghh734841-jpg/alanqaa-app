import 'package:cloud_firestore/cloud_firestore.dart';

/// حالات الطلب المتاحة
enum OrderStatus { pending, making, done, rejected }

extension OrderStatusX on OrderStatus {
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد المراجعة';
      case OrderStatus.making:
        return 'قيد التصنيع';
      case OrderStatus.done:
        return 'تم التسليم';
      case OrderStatus.rejected:
        return 'مرفوض';
    }
  }
}

/// صنف داخل الطلب (مثال: خزانة أرضية × 2)
class OrderItem {
  final String id;
  String name;
  int qty;

  OrderItem({required this.id, required this.name, this.qty = 1});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'qty': qty};

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        qty: (map['qty'] as num?)?.toInt() ?? 1,
      );
}

/// نموذج الطلب الكامل — يُخزَّن كمستند داخل مجموعة "orders" في Firestore
class Order {
  final String id; // معرّف مستند Firestore
  final String code; // مثال: GDC-4
  String galleryName;
  String customerName;
  String customerPhone; // رقم جوال العميل الذي أنشأ الطلب (لتصفية "طلباتي")
  String colorCode;
  List<OrderItem> items;
  String notes;
  String? imageUrl; // رابط صورة المنتج/الرسمة على Firebase Storage
  OrderStatus status;
  double? price;
  bool priceSet;
  bool depositPaid;
  bool fullyPaid;
  int? estimatedDays; // المدة المتوقعة للتنفيذ (تُحدَّد من المدير)
  final DateTime createdAt;

  Order({
    required this.id,
    required this.code,
    required this.galleryName,
    required this.customerName,
    required this.customerPhone,
    required this.colorCode,
    required this.items,
    this.notes = '',
    this.imageUrl,
    this.status = OrderStatus.pending,
    this.price,
    this.priceSet = false,
    this.depositPaid = false,
    this.fullyPaid = false,
    this.estimatedDays,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// تاريخ التسليم المتوقع (يُحسب من تاريخ الإنشاء + المدة المتوقعة)
  DateTime? get estimatedDate =>
      estimatedDays == null ? null : createdAt.add(Duration(days: estimatedDays!));

  Map<String, dynamic> toMap() => {
        'code': code,
        'galleryName': galleryName,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'colorCode': colorCode,
        'items': items.map((e) => e.toMap()).toList(),
        'notes': notes,
        'imageUrl': imageUrl,
        'status': status.name,
        'price': price,
        'priceSet': priceSet,
        'depositPaid': depositPaid,
        'fullyPaid': fullyPaid,
        'estimatedDays': estimatedDays,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    DateTime created;
    if (createdRaw is Timestamp) {
      created = createdRaw.toDate();
    } else {
      created = DateTime.now();
    }
    return Order(
      id: id,
      code: map['code'] as String? ?? '',
      galleryName: map['galleryName'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      colorCode: map['colorCode'] as String? ?? '—',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      notes: map['notes'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      status: OrderStatusX.fromString(map['status'] as String? ?? 'pending'),
      price: (map['price'] as num?)?.toDouble(),
      priceSet: map['priceSet'] as bool? ?? false,
      depositPaid: map['depositPaid'] as bool? ?? false,
      fullyPaid: map['fullyPaid'] as bool? ?? false,
      estimatedDays: (map['estimatedDays'] as num?)?.toInt(),
      createdAt: created,
    );
  }
}

/// بند مرجعي في قائمة أسعار الخامات
class MaterialPrice {
  final String label;
  final double price;
  const MaterialPrice(this.label, this.price);
}

const List<MaterialPrice> kMaterialPriceList = [
  MaterialPrice('متر صاج (جوانب + أرضية + رف) — 4 ملم', 570),
  MaterialPrice('متر وجهة صاج مع درفة فيبر — 2.5 ملم', 600),
  MaterialPrice('صاج كامل (جوانب + أرضية + رف) — 4 ملم', 640),
  MaterialPrice('علبة قطاع خاص + درفة صاج', 670),
];

const double kMinDeposit = 3000;
