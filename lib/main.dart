import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'domain/locations.dart';
import 'presentation/providers/dependencies.dart';
import 'presentation/providers/locations_provider.dart';

/// Local development against the Firebase Emulator Suite instead of the real
/// project. Enable with `--dart-define=USE_EMULATOR=true` and set
/// `--dart-define=EMULATOR_HOST=<host ip>` (Waydroid: 192.168.240.1,
/// Android emulator: 10.0.2.2).
const _useEmulator = bool.fromEnvironment('USE_EMULATOR');
const _emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  }
  final prefs = await SharedPreferences.getInstance();
  final locations = RwandaLocations.fromJson(
    jsonDecode(await rootBundle.loadString('assets/data/rwanda_locations.json')) as List,
  );
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationsProvider.overrideWithValue(locations),
      ],
      child: const NtizaApp(),
    ),
  );
}
