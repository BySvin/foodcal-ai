// PLACEHOLDER — regenerate this file by running:
//   flutterfire configure --project=<your-firebase-project-id>
// from the project root, per the M0 Firebase Bootstrap step in the plan.
// The values below are well-formed but not real, so the app can compile and
// boot before a Firebase project exists. Firebase Auth/Firestore/Storage
// calls will fail until this file is regenerated against a real project.
//
// ignore_for_file: type=lint
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'foodcal-ai-placeholder',
    authDomain: 'foodcal-ai-placeholder.firebaseapp.com',
    storageBucket: 'foodcal-ai-placeholder.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'foodcal-ai-placeholder',
    storageBucket: 'foodcal-ai-placeholder.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'foodcal-ai-placeholder',
    storageBucket: 'foodcal-ai-placeholder.firebasestorage.app',
    iosBundleId: 'com.foodcalai.foodCalorieTracker',
  );
}
