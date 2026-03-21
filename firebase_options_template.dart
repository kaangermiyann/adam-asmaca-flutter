// Firebase Yapılandırma Şablonu
// Bu dosyayı kendi Firebase projenizle yapılandırmanız gerekiyor.
//
// Adımlar:
// 1. https://console.firebase.google.com adresine gidin
// 2. Yeni proje oluşturun veya mevcut bir proje seçin
// 3. Flutter uygulaması ekleyin (iOS/Android)
// 4. firebase_options.dart dosyasını FlutterFire CLI ile oluşturun:
//
//    dart pub global activate flutterfire_cli
//    flutterfire configure
//
// 5. Oluşturulan firebase_options.dart dosyasını lib/ klasörüne kopyalayın
//
// Firestore Kuralları:
// Firebase Console > Firestore Database > Rules bölümüne şu kuralları ekleyin:
//
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//     match /game_rooms/{roomId} {
//       allow read, write: if true;
//     }
//   }
// }
//
// NOT: Üretim için daha güvenli kurallar kullanmanız önerilir.

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

  // Bu değerleri kendi Firebase projenizden alın
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosBundleId: 'com.example.adamAsmaca',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosBundleId: 'com.example.adamAsmaca',
  );
}
