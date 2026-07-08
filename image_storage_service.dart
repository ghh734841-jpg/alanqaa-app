import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// خدمة رفع صور المنتجات إلى Firebase Storage وإرجاع رابط تحميل دائم.
class ImageStorageService {
  final _storage = FirebaseStorage.instance;

  // قمنا بتغيير نوع الإرجاع إلى Future<String?> ليقبل قيمة فارغة (null) في حال فشل الرفع
  Future<String?> uploadOrderImage({
    required String orderId,
    required Uint8List bytes,
  }) async {
    try {
      final ref = _storage.ref().child('orders/$orderId/product.jpg');
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      // في حال فشل الرفع بسبب الباقة المجانية، نطبع الخطأ في الـ Console ونعيد قيمة فارغة
      print("تنبيه: فشل رفع الصورة لعدم ترقية باقة Storage، سيتم إرسال الطلب بدونه: $e");
      return null; 
    }
  }
}
