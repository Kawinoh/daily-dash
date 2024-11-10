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
    apiKey: 'AIzaSyCwO1djCtnMHlqOoPGtcY2nTgtbPyJRSq4',
    appId: '1:451970488829:web:da12cbdb69769b685ae194',
    messagingSenderId: '451970488829',
    projectId: 'daily-dash-9051b',
    authDomain: 'daily-dash-9051b.firebaseapp.com',
    storageBucket: 'daily-dash-9051b.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkrh2SUV1vjco90OPlrkEk-YdxzEZ5c1o',
    appId: '1:451970488829:android:47fc67e967c78f5e5ae194',
    messagingSenderId: '451970488829',
    projectId: 'daily-dash-9051b',
    storageBucket: 'daily-dash-9051b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsjEEp-AN_aPz1AIgfrpLNbEVDt2qGaQ8',
    appId: '1:451970488829:ios:a5d160b0b54e2ddc5ae194',
    messagingSenderId: '451970488829',
    projectId: 'daily-dash-9051b',
    storageBucket: 'daily-dash-9051b.appspot.com',
    iosBundleId: 'com.example.dailydash',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDsjEEp-AN_aPz1AIgfrpLNbEVDt2qGaQ8',
    appId: '1:451970488829:ios:a5d160b0b54e2ddc5ae194',
    messagingSenderId: '451970488829',
    projectId: 'daily-dash-9051b',
    storageBucket: 'daily-dash-9051b.appspot.com',
    iosBundleId: 'com.example.dailydash',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCwO1djCtnMHlqOoPGtcY2nTgtbPyJRSq4',
    appId: '1:451970488829:web:d3ddd17e50980b565ae194',
    messagingSenderId: '451970488829',
    projectId: 'daily-dash-9051b',
    authDomain: 'daily-dash-9051b.firebaseapp.com',
    storageBucket: 'daily-dash-9051b.appspot.com',
  );
}
