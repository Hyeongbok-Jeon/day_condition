import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'bottomNavigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'globalVariables.dart';

Future<void> main() async {
  // 없으면 에러
  WidgetsFlutterBinding.ensureInitialized();

  // firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('ko_KR', null);

  // firebase 익명 로그인
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    G_uid = userCredential.user?.uid.toString();
    print("uid: $G_uid");
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        print("Anonymous auth hasn't been enabled for this project.");
        break;
      default:
        print("Unknown error.");
    }
  }

  // 기본 설정값 셋팅
  final snapshotValue = <dynamic, dynamic>{};
  final ref = FirebaseDatabase.instance.ref('$G_uid/settings');
  final snapshot = await ref.get();
  for (final child in snapshot.children) {
    snapshotValue[child.key] = child.value;
  }
  ref.update(
      {'startingDayOfWeek': snapshotValue['startingDayOfWeek'] ?? 'sunday'});

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BottomNavigationExample(),
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
    );
  }
}