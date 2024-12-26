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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7OjAZOurYx-5fKxFh1kC5i0jAK75rqGM',
    appId: '1:905377210116:android:d18e1b9d1586c1339b7a51',
    messagingSenderId: '905377210116',
    projectId: 'blackbox-31f96',
    databaseURL: 'https://blackbox-31f96-default-rtdb.firebaseio.com',
    storageBucket: 'blackbox-31f96.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8mG6QR9dM_FhmEJOiHEmm4_sFDbWan0A',
    appId: '1:905377210116:ios:48937f3ac57e782e9b7a51',
    messagingSenderId: '905377210116',
    projectId: 'blackbox-31f96',
    databaseURL: 'https://blackbox-31f96-default-rtdb.firebaseio.com',
    storageBucket: 'blackbox-31f96.firebasestorage.app',
    iosBundleId: 'com.edu.blackBox',
  );

}