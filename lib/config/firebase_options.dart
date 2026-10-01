import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseOptionsConfig {
  static FirebaseOptions get web {
    if (!kIsWeb) {
      throw UnsupportedError(
        'As opcoes web do Firebase nao sao suportadas aqui.',
      );
    }
    return const FirebaseOptions(
      apiKey: 'AIzaSyB2SfZLGsbn5rt-Juw_mA9d0Nwl0yU1iVc',
      appId: '1:1093809342544:web:ec000c6f5c6cd5bffa6955',
      messagingSenderId: '1093809342544',
      projectId: 'sqeducaplay',
      authDomain: 'sqeducaplay.firebaseapp.com',
      storageBucket: 'sqeducaplay.firebasestorage.app',
    );
  }
}
