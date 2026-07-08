import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة تسجيل الدخول برقم الجوال عبر Firebase Auth (OTP / رمز التحقق)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// رقم الجوال الحالي بصيغة دولية (مثال: +9665xxxxxxxx) أو null
  String? get currentPhone => _auth.currentUser?.phoneNumber;

  /// تحويل رقم جوال سعودي محلي (05xxxxxxxx) إلى صيغة دولية +9665xxxxxxxx.
  /// إن كان الرقم مكتوبًا مسبقًا بصيغة دولية (يبدأ بـ +) يُترك كما هو.
  static String toInternational(String raw) {
    var v = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (v.startsWith('+')) return v;
    if (v.startsWith('00')) return '+${v.substring(2)}';
    if (v.startsWith('0')) return '+966${v.substring(1)}';
    if (v.startsWith('966')) return '+$v';
    return '+966$v';
  }

  /// الخطوة ١: إرسال رمز التحقق SMS إلى الرقم.
  ///
  /// [onCodeSent] يُستدعى بمعرّف العملية (verificationId) بعد نجاح الإرسال.
  /// [onError] يُستدعى برسالة الخطأ إن فشل الإرسال.
  /// [onAutoVerified] يُستدعى تلقائيًا في حال تحقق أندرويد من الرمز تلقائيًا
  /// دون الحاجة لإدخال المستخدم للكود (ميزة اختيارية من Firebase).
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
    void Function()? onAutoVerified,
  }) async {
    final formatted = toInternational(phone);
    await _auth.verifyPhoneNumber(
      phoneNumber: formatted,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified?.call();
        } catch (e) {
          onError('تعذّر تسجيل الدخول تلقائيًا: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_mapError(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// الخطوة ٢: تأكيد رمز التحقق الذي وصل بالـ SMS وتسجيل الدخول.
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
    await _ensureUserDoc();
  }

  /// إنشاء/تحديث مستند بيانات المستخدم عند أول تسجيل دخول
  Future<void> _ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'phone': user.phoneNumber,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// هل رقم الجوال الحالي مدرج ضمن قائمة المدراء (مجموعة admins في Firestore)؟
  /// أضف رقم أي مدير يدويًا من Firebase Console كمستند داخل هذه المجموعة،
  /// حيث يكون معرّف المستند (Document ID) هو رقم الجوال بصيغة دولية،
  /// مثال: مستند بمعرّف +966501234567 داخل مجموعة admins.
  Future<bool> checkIsAdmin() async {
    final phone = currentPhone;
    if (phone == null) return false;
    final doc = await _db.collection('admins').doc(phone).get();
    return doc.exists;
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الجوال غير صحيح، تأكد من كتابته بشكل صحيح.';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول مرة أخرى بعد قليل.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح.';
      case 'session-expired':
        return 'انتهت صلاحية الرمز، اطلب رمزًا جديدًا.';
      default:
        return e.message ?? 'حدث خطأ غير متوقع، حاول مرة أخرى.';
    }
  }
}
