import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'bottomNavigation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/local_store.dart';

Future<void> main() async {
  /// 없으면 에러
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);

  // 기록과 설정은 기기(웹은 브라우저)에 저장한다.
  await LocalStore.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool useMaterial3 = true;
  ThemeMode themeMode = ThemeMode.system;

  bool get useLightMode {
    switch (themeMode) {
      case ThemeMode.system:
        return View.of(context).platformDispatcher.platformBrightness == Brightness.light;
      case ThemeMode.light:
        return true;
      case ThemeMode.dark:
        return false;
    }
  }

  void handleBrightnessChange(bool useLightMode) {
    setState(() {
      themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '하루 컨디션',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: useMaterial3,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: useMaterial3,
        brightness: Brightness.dark,
      ),
      home: BottomNavigationExample(useLightMode: useLightMode, handleBrightnessChange: handleBrightnessChange),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      locale: const Locale('ko'),
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black,
            ),
            Center(
              child: SizedBox(
                width: 500,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
