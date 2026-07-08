import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';

/// خدمة تصدير الطلب: تنزيل/مشاركة صورة المنتج، أو توليد ملف PDF بكل
/// تفاصيل الطلب (يشمل الصورة) ومشاركته — من قائمة المشاركة يقدر المستخدم
/// يحفظه في الملفات أو معرض الصور مباشرة.
class ExportService {
  Future<Uint8List> _download(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('تعذّر تحميل الملف (كود ${res.statusCode})');
    }
    return res.bodyBytes;
  }

  /// مشاركة/تنزيل صورة المنتج كما هي
  Future<void> shareImage({required String imageUrl, required String filename}) async {
    final bytes = await _download(imageUrl);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'صورة الطلب');
  }

  /// توليد ملف PDF يلخّص الطلب (بيانات العميل، الأصناف، السعر، المدة
  /// المتوقعة، وصورة المنتج إن وُجدت) ومشاركته/حفظه.
  Future<void> shareOrderPdf(Order order) async {
    final regular = await PdfGoogleFonts.notoNaskhArabicRegular();
    final bold = await PdfGoogleFonts.notoNaskhArabicBold();

    pw.MemoryImage? productImage;
    if (order.imageUrl != null) {
      try {
        productImage = pw.MemoryImage(await _download(order.imageUrl!));
      } catch (_) {
        // تجاهل الصورة إن تعذّر تحميلها ولا نوقف توليد الملف
      }
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('شركة العنقاء للمقاولات', style: pw.TextStyle(font: bold, fontSize: 20)),
                pw.SizedBox(height: 2),
                pw.Text('تفاصيل الطلب ${order.code}', style: pw.TextStyle(font: regular, fontSize: 13, color: PdfColors.grey700)),
                pw.SizedBox(height: 14),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                _row('إسم المعرض', order.galleryName, regular, bold),
                _row('إسم الزبون', order.customerName, regular, bold),
                _row('رقم الجوال', order.customerPhone, regular, bold),
                _row('رمز اللون', order.colorCode, regular, bold),
                _row('الحالة', order.status.label, regular, bold),
                if (order.priceSet) _row('السعر', '${order.price!.toStringAsFixed(0)} ريال', regular, bold),
                if (order.estimatedDays != null) _row('المدة المتوقعة', '${order.estimatedDays} يوم', regular, bold),
                pw.SizedBox(height: 14),
                pw.Text('الأصناف', style: pw.TextStyle(font: bold, fontSize: 13)),
                pw.SizedBox(height: 6),
                ...order.items.map(
                  (it) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text('•  ${it.name}  ×  ${it.qty}', style: pw.TextStyle(font: regular, fontSize: 12)),
                  ),
                ),
                if (order.notes.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Text('ملاحظات', style: pw.TextStyle(font: bold, fontSize: 13)),
                  pw.SizedBox(height: 4),
                  pw.Text(order.notes, style: pw.TextStyle(font: regular, fontSize: 12)),
                ],
                if (productImage != null) ...[
                  pw.SizedBox(height: 18),
                  pw.Text('صورة المنتج', style: pw.TextStyle(font: bold, fontSize: 13)),
                  pw.SizedBox(height: 8),
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(productImage, height: 240, fit: pw.BoxFit.cover),
                  ),
                ],
                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 6),
                pw.Text(
                  'عربون ${kMinDeposit.toStringAsFixed(0)} ريال على الأقل قبل بدء التنفيذ، وسداد كامل المبلغ قبل خروج المطبخ من الورشة.',
                  style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: '${order.code}.pdf');
  }

  pw.Widget _row(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 90, child: pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 12))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 12))),
        ],
      ),
    );
  }
}
