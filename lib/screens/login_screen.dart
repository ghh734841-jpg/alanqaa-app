import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _verificationId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 9) {
      setState(() => _error = 'اكتب رقم جوال صحيح');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await _auth.sendOtp(
      phone: phone,
      onCodeSent: (id) {
        setState(() {
          _verificationId = id;
          _loading = false;
        });
      },
      onError: (msg) {
        setState(() {
          _error = msg;
          _loading = false;
        });
      },
      onAutoVerified: () {
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _codeCtrl.text.trim().length < 4) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.verifyOtp(verificationId: _verificationId!, smsCode: _codeCtrl.text.trim());
    } catch (e) {
      setState(() => _error = 'رمز التحقق غير صحيح، حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.handyman_outlined, color: AppColors.teal, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('شركة العنقاء للمقاولات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                _verificationId == null
                    ? 'سجّل الدخول برقم جوالك للمتابعة'
                    : 'أدخل رمز التحقق المُرسل إلى ${_phoneCtrl.text}',
                style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              if (_verificationId == null) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Color(0xFF1B2532)),
                  decoration: const InputDecoration(
                    hintText: '05xxxxxxxx',
                    prefixIcon: Icon(Icons.phone_iphone, color: AppColors.textFaint),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDeep))
                      : const Text('إرسال رمز التحقق'),
                ),
              ] else ...[
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF1B2532), fontSize: 20, letterSpacing: 6),
                  decoration: const InputDecoration(hintText: '——————'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyCode,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDeep))
                      : const Text('تأكيد الدخول'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _verificationId = null;
                            _codeCtrl.clear();
                          }),
                  child: const Text('تغيير رقم الجوال', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.red.withOpacity(0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12.5)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
