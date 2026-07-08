import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final bool admin;
  final void Function(OrderStatus status)? onStatusChange;
  final void Function(double price)? onSetPrice;
  final void Function(String field)? onTogglePayment; // 'depositPaid' | 'fullyPaid'
  final void Function(int days)? onSetEstimatedDays;

  const OrderCard({
    super.key,
    required this.order,
    this.admin = false,
    this.onStatusChange,
    this.onSetPrice,
    this.onTogglePayment,
    this.onSetEstimatedDays,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final _export = ExportService();
  late TextEditingController _priceCtrl;
  late TextEditingController _daysCtrl;
  bool _editingPrice = false;
  bool _editingDays = false;
  bool _exportingImage = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.order.price != null ? widget.order.price!.toStringAsFixed(0) : '',
    );
    _daysCtrl = TextEditingController(
      text: widget.order.estimatedDays != null ? widget.order.estimatedDays.toString() : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  void _savePrice() {
    final n = double.tryParse(_priceCtrl.text.trim());
    if (n == null || n <= 0) return;
    widget.onSetPrice?.call(n);
    setState(() => _editingPrice = false);
  }

  void _saveDays() {
    final n = int.tryParse(_daysCtrl.text.trim());
    if (n == null || n <= 0) return;
    widget.onSetEstimatedDays?.call(n);
    setState(() => _editingDays = false);
  }

  Future<void> _downloadImage() async {
    final o = widget.order;
    if (o.imageUrl == null || _exportingImage) return;
    setState(() => _exportingImage = true);
    try {
      await _export.shareImage(imageUrl: o.imageUrl!, filename: '${o.code}.jpg');
    } catch (e) {
      _showError('تعذّر تنزيل الصورة، حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _exportingImage = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      await _export.shareOrderPdf(widget.order);
    } catch (e) {
      _showError('تعذّر إنشاء ملف PDF، حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الطلب ${o.code}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd-MM-yyyy').format(o.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: o.status),
            ],
          ),

          if (o.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                o.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 160,
                    alignment: Alignment.center,
                    color: AppColors.surfaceAlt,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  height: 160,
                  alignment: Alignment.center,
                  color: AppColors.surfaceAlt,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textFaint),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _exportButton('تنزيل الصورة', Icons.download_outlined, _exportingImage, _downloadImage)),
                const SizedBox(width: 8),
                Expanded(child: _exportButton('تنزيل PDF', Icons.picture_as_pdf_outlined, _exportingPdf, _downloadPdf)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _exportButton('تنزيل PDF', Icons.picture_as_pdf_outlined, _exportingPdf, _downloadPdf, compact: true),
            ),
          ],

          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _infoText('إسم المعرض', o.galleryName),
              _infoText('إسم الزبون', o.customerName),
              _infoText('رمز اللون', o.colorCode),
            ],
          ),

          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: o.items
                .map((it) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${it.name} × ${it.qty}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFC4CEDB))),
                    ))
                .toList(),
          ),

          if (o.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('ملاحظات: ${o.notes}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6)),
          ],

          const Divider(height: 28, color: AppColors.border),

          // السعر
          Row(
            children: [
              if (o.priceSet && !_editingPrice)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('${o.price!.toStringAsFixed(0)} ريال',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      const Text('— تم رفعه من الشركة',
                          style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                    ],
                  ),
                )
              else if (!widget.admin)
                const Expanded(
                  child: Text('لم يتم رفع السعر بعد',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textFaint)),
                )
              else
                const Spacer(),
              if (widget.admin)
                if (_editingPrice || !o.priceSet)
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B2532)),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'السعر',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _savePrice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(fontSize: 12.5),
                        ),
                        child: const Text('حفظ السعر'),
                      ),
                    ],
                  )
                else
                  OutlinedButton(
                    onPressed: () => setState(() => _editingPrice = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: Color(0xFF3A4A5E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تعديل السعر', style: TextStyle(fontSize: 12)),
                  ),
            ],
          ),

          // المدة المتوقعة
          const SizedBox(height: 12),
          Row(
            children: [
              if (o.estimatedDays != null && !_editingDays)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 16, color: AppColors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المدة المتوقعة: ${o.estimatedDays} يوم'
                          '${o.estimatedDate != null ? ' (حتى ${DateFormat('dd-MM-yyyy').format(o.estimatedDate!)})' : ''}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!widget.admin)
                const Expanded(
                  child: Text('لم تُحدَّد المدة المتوقعة بعد',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textFaint)),
                )
              else
                const Spacer(),
              if (widget.admin)
                if (_editingDays || o.estimatedDays == null)
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _daysCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B2532)),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'عدد الأيام',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _saveDays,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(fontSize: 12.5),
                        ),
                        child: const Text('حفظ'),
                      ),
                    ],
                  )
                else
                  OutlinedButton(
                    onPressed: () => setState(() => _editingDays = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: Color(0xFF3A4A5E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تعديل المدة', style: TextStyle(fontSize: 12)),
                  ),
            ],
          ),

          if (!widget.admin && o.priceSet) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'عربون ${kMinDeposit.toStringAsFixed(0)} ريال على الأقل لبدء التنفيذ، والباقي يُسدد قبل خروج المطبخ من الورشة.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8FD9CF), height: 1.7),
              ),
            ),
          ],

          if (widget.admin) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _statusButton(
                    label: 'قيد التصنيع',
                    icon: Icons.build_outlined,
                    color: AppColors.blue,
                    active: o.status == OrderStatus.making,
                    onTap: () => widget.onStatusChange?.call(OrderStatus.making),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusButton(
                    label: 'تم التسليم',
                    icon: Icons.local_shipping_outlined,
                    color: AppColors.green,
                    active: o.status == OrderStatus.done,
                    onTap: () => widget.onStatusChange?.call(OrderStatus.done),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusButton(
                    label: 'رفض الطلب',
                    icon: Icons.block,
                    color: AppColors.red,
                    active: o.status == OrderStatus.rejected,
                    onTap: () => widget.onStatusChange?.call(OrderStatus.rejected),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _checkRow(
                    label: 'العربون مدفوع',
                    value: o.depositPaid,
                    onChanged: () => widget.onTogglePayment?.call('depositPaid'),
                  ),
                ),
                Expanded(
                  child: _checkRow(
                    label: 'المبلغ الكامل مدفوع',
                    value: o.fullyPaid,
                    onChanged: () => widget.onTogglePayment?.call('fullyPaid'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
        children: [
          TextSpan(text: '$label  '),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _exportButton(String label, IconData icon, bool loading, VoidCallback onTap, {bool compact = false}) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted))
          : Icon(icon, size: 15, color: AppColors.textMuted),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF3A4A5E)),
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 9, horizontal: compact ? 10 : 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? color.withOpacity(0.18) : Colors.transparent,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _checkRow({required String label, required bool value, required VoidCallback onChanged}) {
    return InkWell(
      onTap: onChanged,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (_) => onChanged(),
            activeColor: AppColors.teal,
            visualDensity: VisualDensity.compact,
          ),
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
