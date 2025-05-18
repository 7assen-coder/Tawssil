import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'homepage.dart';
import 'translations/codegen_loader.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // تعطيل سطر الخطأ الأحمر في أسفل الشاشة
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const CodegenLoader(),
      saveLocale: true,
      useFallbackTranslations: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Tawssil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F9C95)),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2F9C95),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F9C95),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // تخصيص العرض وإخفاء رسائل الخطأ في أسفل الشاشة
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Container();
        };

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
          child: child!,
        );
      },
    );
  }
}
