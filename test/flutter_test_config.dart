import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Roboto for every test so text is measured with realistic glyph
/// widths. The default test font (Ahem) is much wider and reports overflows
/// that never happen on a device.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Roboto');
  for (final file in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('test/fonts/Roboto-$file.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  await testMain();
}
