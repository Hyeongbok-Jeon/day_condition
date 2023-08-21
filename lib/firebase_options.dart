import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGyNzQ-q2woF1KZSUOcq2nM7ZbnxRqUOI',
    appId: '1:784631214517:web:8725c1c4d9859fbe8fa9fc',
    messagingSenderId: '784631214517',
    projectId: 'daycondition-198dd',
    authDomain: 'daycondition-198dd.firebaseapp.com',
    databaseURL: 'https://daycondition-198dd-default-rtdb.firebaseio.com',
    storageBucket: 'daycondition-198dd.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTMHpX_0Lyn-f1j8lhOjP-AwnYyKcFr1c',
    appId: '1:784631214517:android:eb84b0a9ea572fbf8fa9fc',
    messagingSenderId: '784631214517',
    projectId: 'daycondition-198dd',
    databaseURL: 'https://daycondition-198dd-default-rtdb.firebaseio.com',
    storageBucket: 'daycondition-198dd.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzrWRKZbTfHVW6FdLkykV16uxB3OXrGUQ',
    appId: '1:784631214517:ios:8c373ead3846c1c68fa9fc',
    messagingSenderId: '784631214517',
    projectId: 'daycondition-198dd',
    databaseURL: 'https://daycondition-198dd-default-rtdb.firebaseio.com',
    storageBucket: 'daycondition-198dd.appspot.com',
    iosClientId:
        '784631214517-6svs4m7mtulb7aovtsn8tsbu93h2qjmq.apps.googleusercontent.com',
    iosBundleId: 'com.example.dayCondition',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDzrWRKZbTfHVW6FdLkykV16uxB3OXrGUQ',
    appId: '1:784631214517:ios:8c373ead3846c1c68fa9fc',
    messagingSenderId: '784631214517',
    projectId: 'daycondition-198dd',
    databaseURL: 'https://daycondition-198dd-default-rtdb.firebaseio.com',
    storageBucket: 'daycondition-198dd.appspot.com',
    iosClientId:
        '784631214517-6svs4m7mtulb7aovtsn8tsbu93h2qjmq.apps.googleusercontent.com',
    iosBundleId: 'com.example.dayCondition',
  );
}
