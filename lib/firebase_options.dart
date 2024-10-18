// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
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
    apiKey: 'AIzaSyCSJOO4v7GjBINmCCXctbODU7P799GAEVA',
    appId: '1:400942111580:web:958d484e58132120e03f99',
    messagingSenderId: '400942111580',
    projectId: 'specimen-copy',
    authDomain: 'specimen-copy.firebaseapp.com',
    storageBucket: 'specimen-copy.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUSnd4FcMvErkK2GJH1Jwm4NrMSBHBZLA',
    appId: '1:400942111580:android:58a0cf988b1e1235e03f99',
    messagingSenderId: '400942111580',
    projectId: 'specimen-copy',
    storageBucket: 'specimen-copy.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2mRubNXE566QBy_DQqaxswY7HSaktY3I',
    appId: '1:400942111580:ios:38b7335c898d1103e03f99',
    messagingSenderId: '400942111580',
    projectId: 'specimen-copy',
    storageBucket: 'specimen-copy.appspot.com',
    iosBundleId: 'com.example.flutterspecimencopy',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB2mRubNXE566QBy_DQqaxswY7HSaktY3I',
    appId: '1:400942111580:ios:38b7335c898d1103e03f99',
    messagingSenderId: '400942111580',
    projectId: 'specimen-copy',
    storageBucket: 'specimen-copy.appspot.com',
    iosBundleId: 'com.example.flutterspecimencopy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCSJOO4v7GjBINmCCXctbODU7P799GAEVA',
    appId: '1:400942111580:web:3faadfed480cf8c8e03f99',
    messagingSenderId: '400942111580',
    projectId: 'specimen-copy',
    authDomain: 'specimen-copy.firebaseapp.com',
    storageBucket: 'specimen-copy.appspot.com',
  );
}