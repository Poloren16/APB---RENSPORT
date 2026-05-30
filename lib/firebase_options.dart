import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw _notConfigured('ios');
      case TargetPlatform.macOS:
        throw _notConfigured('macos');
      case TargetPlatform.windows:
        throw _notConfigured('windows');
      case TargetPlatform.linux:
        throw _notConfigured('linux');
      default:
        throw _notConfigured(defaultTargetPlatform.name);
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtqqrc7abHykp8GVFwAeMdGFIZIUf9WJs',
    authDomain: 'rensius.firebaseapp.com',
    projectId: 'rensius',
    storageBucket: 'rensius.firebasestorage.app',
    messagingSenderId: '786242129327',
    appId: '1:786242129327:web:abec7ce7f2ef4786a4335a',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtqqrc7abHykp8GVFwAeMdGFIZIUf9WJs',
    appId: '1:786242129327:android:dda1af1c10ca68c9a4335a',
    messagingSenderId: '786242129327',
    projectId: 'rensius',
    storageBucket: 'rensius.firebasestorage.app',
  );

  static UnsupportedError _notConfigured(String platform) {
    return UnsupportedError(
      'Firebase belum dikonfigurasi untuk $platform. Jalankan '
      '`flutterfire configure` dan pilih platform tersebut.',
    );
  }
}
