import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'bottomNavigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'globalVariables.dart';

Future<void> main() async {
  /// 없으면 에러
  WidgetsFlutterBinding.ensureInitialized();

  /// firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('ko_KR', null);

  // firebase 익명 로그인
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    G_uid = userCredential.user?.uid.toString();
    if (kDebugMode) {
      print("uid: $G_uid");
    }
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        if (kDebugMode) {
          print("Anonymous auth hasn't been enabled for this project.");
        }
        break;
      default:
        if (kDebugMode) {
          print("Unknown error.");
        }
    }
  }

  // uid 없이 진행하면 모든 DB 경로가 루트('/')를 가리키게 되어, 데이터 초기화 시
  // 전체 데이터가 지워질 수 있다. 로그인에 실패하면 앱을 진행하지 않는다.
  if (G_uid == null || G_uid!.isEmpty) {
    runApp(const StartupErrorApp('로그인에 실패했습니다.\n네트워크 연결을 확인한 뒤 앱을 다시 실행해 주세요.'));
    return;
  }

  // 기본 설정값 셋팅. DB에 연결할 수 없으면 빈 화면으로 멈추지 않고 안내한다.
  try {
    final snapshotValue = <dynamic, dynamic>{};
    final ref = FirebaseDatabase.instance.ref('$G_uid/settings');
    final snapshot = await ref.get().timeout(const Duration(seconds: 10));
    for (final child in snapshot.children) {
      snapshotValue[child.key] = child.value;
    }
    ref.update({'startingDayOfWeek': snapshotValue['startingDayOfWeek'] ?? 'sunday'});
  } catch (e) {
    if (kDebugMode) {
      print('Database unavailable: $e');
    }
    runApp(const StartupErrorApp('서버에 연결할 수 없습니다.\n잠시 후 다시 시도해 주세요.'));
    return;
  }

  /// 지속성 동작
  // FirebaseDatabase.instance.setPersistenceEnabled(true);

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

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
