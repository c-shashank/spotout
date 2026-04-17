import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    if (kIsWeb) {
      const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const firebaseAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
      const firebaseMessagingSenderId =
          String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
      const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
      const firebaseStorageBucket =
          String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

      if (firebaseApiKey.isEmpty ||
          firebaseAppId.isEmpty ||
          firebaseMessagingSenderId.isEmpty ||
          firebaseProjectId.isEmpty ||
          firebaseAuthDomain.isEmpty ||
          firebaseStorageBucket.isEmpty) {
        throw StateError(
          'Missing Firebase Web config. Pass FIREBASE_API_KEY, '
          'FIREBASE_WEB_APP_ID, FIREBASE_MESSAGING_SENDER_ID, '
          'FIREBASE_PROJECT_ID, FIREBASE_AUTH_DOMAIN, and '
          'FIREBASE_STORAGE_BUCKET via --dart-define.',
        );
      }

      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: firebaseApiKey,
          appId: firebaseAppId,
          messagingSenderId: firebaseMessagingSenderId,
          projectId: firebaseProjectId,
          authDomain: firebaseAuthDomain,
          storageBucket: firebaseStorageBucket,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    // Supabase RLS uses auth.uid(); with Firebase phone/email auth we must send the
    // Firebase ID token on each request. Enable Firebase in Supabase Dashboard →
    // Authentication → Third-party auth, and ensure users have role: 'authenticated'
    // in Firebase custom claims (see Supabase Firebase Auth guide).
    // NOTE: To use Firebase JWTs for Supabase RLS (auth.uid() checks), configure
    // Supabase Dashboard → Authentication → Third-party auth → Firebase.
    // Until then, requests use the anon key — read operations and the bootstrap
    // INSERT policy work; user-scoped writes (votes, bookmarks) need the config.
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );

    runApp(const Jawab DoApp());
  } catch (e, st) {
    debugPrint('Startup failed: $e');
    debugPrintStack(stackTrace: st);
    runApp(_StartupErrorApp(error: e.toString()));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'App startup failed:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
