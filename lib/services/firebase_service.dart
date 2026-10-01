import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  firebase_auth.FirebaseAuth get auth {
    _ensureInitialized();
    return firebase_auth.FirebaseAuth.instance;
  }

  FirebaseFirestore get firestore {
    _ensureInitialized();
    return FirebaseFirestore.instance;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      await Firebase.initializeApp(options: FirebaseOptionsConfig.web);
    } else {
      await Firebase.initializeApp();
    }
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('Firebase ainda nao foi inicializado.');
    }
  }
}
