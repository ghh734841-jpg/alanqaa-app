import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../services/image_storage_service.dart';
import '../services/orders_repository.dart';
import '../theme/app_theme.dart';

class NewOrderScreen extends StatefulWidget {
  final OrdersRepository repository;
  final String customerPhone;
  final VoidCallback onSubmitted;

  const NewOrderScreen({
    super.key,
    required this.repository,
    required this.customerPhone,
    required this.onSubmitted,
  });

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _galleryCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<OrderItem> _items = [OrderItem(id: const Uuid().v4(), name: '')];

  Uint8List? _imageBytes;
  bool _uploading = false;
  bool _submitting = false;
  final _imageStorage = ImageStorageService();

  @override
  void dispose() {
    _galleryCtrl.dispose();
    _customerCtrl.dispose();
    _colorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _galleryCtrl.text.trim().isNotEmpty &&
      _customerCtrl.text.trim().isNotEmpty &&
      _items.any((i) => i.name.trim().isNotEmpty);

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 65,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _addItem() => setState(() => _items.add(OrderItem(id: const Uuid().v4(), name: '')));

  void _removeItem(String id) {
    if (_items.length <= 1) return;
    setState(() => _items.removeWhere((i) => i.id == id));
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final id = const Uuid().v4();
      String? imageUrl;
      
      if (_imageBytes != null) {
        try {
          imageUrl = await _imageStorage.uploadOrderImage(orderId: id, bytes: _imageBytes!);
        } catch (e) {
          imageUrl = ""; 
        }
      }
      
      final count = await widget.repository.getOrderCount();
      final order = Order(
        id: id,
        code: 'GDC-${count + 1}',
        galleryName: _galleryCtrl.text.trim(),
        customerName: _customerCtrl.text.trim(),
        customerPhone: widget.customerPhone,
        colorCode: _colorCtrl.text.trim().isEmpty ? '—' : _colorCtrl.text.trim(),
        items: _items.where((i) => i.name.trim().isNotEmpty).toList(),
        notes: _notesCtrl.text.trim(),
        imageUrl: imageUrl ?? "", 
      );
      
      await widget.repository.addOrder(order);

      _galleryCtrl.clear();
      _customerCtrl.clear();
      _colorCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _items = [OrderItem(id: const Uuid().v4(), name: '')];
        _imageBytes = null;
      });
      widget.onSubmitted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر إرسال الطلب، حاول مرة أخرى: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionCard([
          _fieldLabel('إسم المعرض', Icons.storefront_outlined),
          TextField(controller: _galleryCtrl, decoration: const InputDecoration(hintText: 'مثال: معرض كوين')),
          const SizedBox(height: 18),
          _fieldLabel('إسم الزبون', Icons.person_outline),
          TextField(controller: _customerCtrl, decoration: const InputDecoration(hintText: 'اسم الزبون')),
        ]),
        const SizedBox(height: 16),
        _sectionCard([
          _fieldLabel('رمز اللون', Icons.palette_outlined),
          TextField(controller: _colorCtrl, decoration: const InputDecoration(hintText: 'مثال: 6G9')),
          const SizedBox(height: 18),
          const Text('الأصناف',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final item in _items) _itemRow(item),
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 16, color: AppColors.blue),
            label: const Text('إضافة صنف', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        _sectionCard([
          _fieldLabel('صورة المنتج', Icons.image_outlined),
          _imagePickerBox(),
          const SizedBox(height: 18),
          _fieldLabel('ملاحظات (اختياري)', Icons.notes_outlined),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'قم بإدخال ملاحظاتك'),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.1),
            border: Border.all(color: AppColors.amber.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFE0C090), height: 1.8),
                    children: [
                      TextSpan(text: 'يُرجى دفع عربون '),
                      TextSpan(
                        text: '3000 ريال',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                          text:
                              ' على الأقل قبل بدء الرسمة أو تجهيز المطبخ، ودفع كامل المبلغ قبل خروج المطبخ من الورشة.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: (_valid && !_submitting) ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDeep))
              : const Text('إرسال الطلب'),
        ),
      ],
    );
  }

  Widget _itemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _stepperButton(Icons.remove, () => _removeItem(item.id)),
          SizedBox(
            width: 28,
            child: Text('${item.qty}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ),
          _stepperButton(Icons.add, () => setState(() => item.qty++)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: item.name,
              onChanged: (v) => item.name = v,
              decoration: const InputDecoration(hintText: 'اسم الصنف (مثال: خزانة أرضية)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(16)), // تم تغيير لون الخلفية ليتوافق مع AppColors المتوفرة لديك
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _fieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _imagePickerBox() {
    return InkWell(
      onTap: _uploading ? null : _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _imageBytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity))
            : const Center(child: Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 32)),
      ),
    );
  }
}
