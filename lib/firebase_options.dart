// Firebase Yapılandırma Dosyası
// ÖNEMLİ: Bu dosyayı kendi Firebase projenizle yapılandırmanız gerekiyor.
//
// Adımlar:
// 1. https://console.firebase.google.com adresine gidin
// 2. Yeni proje oluşturun
// 3. Flutter uygulaması ekleyin
// 4. FlutterFire CLI ile yapılandırın:
//    dart pub global activate flutterfire_cli
//    flutterfire configure

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
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // PLACEHOLDER - Bu değerleri kendi Firebase projenizden alın
  // flutterfire configure komutu ile otomatik oluşturulabilir
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:000000000000:web:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:000000000000:android:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:000000000000:ios:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.example.adamAsmaca',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:000000000000:macos:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.example.adamAsmaca',
  );
}
