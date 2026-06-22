import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'pages/login_page.dart';
import 'data/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppEnv.isConfigured) {
    debugPrint(
      'Firebase não configurado. Use: .\\scripts\\run_local.ps1 '
      'ou flutter run --dart-define-from-file=env.json',
    );
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp() falhou: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passa a Bola',
      theme: ThemeData(
        useMaterial3: true,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        primarySwatch: Colors.deepPurple,
        primaryColor: KConstants.primaryColor,
        scaffoldBackgroundColor: kIsWeb
            ? const Color(0xFFF5F5F7)
            : KConstants.backgroundColor,
        visualDensity: kIsWeb ? VisualDensity.standard : VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: KConstants.primaryColor,
          foregroundColor: KConstants.textLightColor,
          titleTextStyle: KTextStyle.titleText.copyWith(
            color: KConstants.textLightColor,
            fontSize: KConstants.fontSizeLarge,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: KTextStyle.titleText,
          titleMedium: KTextStyle.subtitleText,
          bodyLarge: KTextStyle.bodyText,
          bodyMedium: KTextStyle.bodySecondaryText,
          labelLarge: KTextStyle.buttonText,
        ),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
