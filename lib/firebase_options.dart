// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyCNEU5pZ40xeE-77o_jtKXxptz5ih_7pvo',
    appId: '1:688520948191:web:0967587245369743997c6a',
    messagingSenderId: '688520948191',
    projectId: 'arvo-bb0ae',
    authDomain: 'arvo-bb0ae.firebaseapp.com',
    storageBucket: 'arvo-bb0ae.firebasestorage.app',
    measurementId: 'G-Z3LZ6BZ556',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6M8fcustp7NaqiFl8vQUVHPMBPXXEFZU',
    appId: '1:688520948191:android:4fd4441ae1b004a6997c6a',
    messagingSenderId: '688520948191',
    projectId: 'arvo-bb0ae',
    storageBucket: 'arvo-bb0ae.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKggZpy2WI6bMAqjcSK3ZP4bE13u4zgt0',
    appId: '1:688520948191:ios:73479888dd9c052f997c6a',
    messagingSenderId: '688520948191',
    projectId: 'arvo-bb0ae',
    storageBucket: 'arvo-bb0ae.firebasestorage.app',
    iosBundleId: 'com.n3.arvo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAKggZpy2WI6bMAqjcSK3ZP4bE13u4zgt0',
    appId: '1:688520948191:ios:73479888dd9c052f997c6a',
    messagingSenderId: '688520948191',
    projectId: 'arvo-bb0ae',
    storageBucket: 'arvo-bb0ae.firebasestorage.app',
    iosBundleId: 'com.n3.arvo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCNEU5pZ40xeE-77o_jtKXxptz5ih_7pvo',
    appId: '1:688520948191:web:1bec6ba3ae1f0879997c6a',
    messagingSenderId: '688520948191',
    projectId: 'arvo-bb0ae',
    authDomain: 'arvo-bb0ae.firebaseapp.com',
    storageBucket: 'arvo-bb0ae.firebasestorage.app',
    measurementId: 'G-LL4T3TJX21',
  );

}