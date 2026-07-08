import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // نعتمد على ملفي الإعداد الأصليين اللذين وضعتهما في المشروع:
  //   android/app/google-services.json
  //   ios/Runner/GoogleService-Info.plist
  // لذلك لا حاجة لتمرير FirebaseOptions يدويًا هنا.
  await Firebase.initializeApp();
  runApp(const GdcOrdersApp());
}

class GdcOrdersApp extends StatelessWidget {
  const GdcOrdersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شركة العنقاء للمقاولات',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // دعم اللغة العربية واتجاه الكتابة من اليمين لليسار
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

/// بوابة الدخول: تعرض شاشة تسجيل الدخول برقم الجوال إن لم يكن هناك جلسة
/// مسجّلة، وإلا تنتقل مباشرة للشاشة الرئيسية. الدخول برقم الجوال **إلزامي**
/// قبل الوصول لأي جزء من التطبيق (عميل أو مدير).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.bgDeep,
            body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}
