import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Roboto from the Flutter SDK cache so widget tests measure text the
/// way a phone does. The default test font draws every glyph as a wide box,
/// which makes overflow checks meaningless.
///
/// Returns false when the SDK fonts are not available; callers should skip
/// their layout assertions in that case instead of failing.
Future<bool> loadRealFonts() async {
  // Under `flutter test` the executable is flutter_tester inside the SDK
  // cache; walk up until the SDK root that holds the material fonts.
  Directory? fontsDir;
  for (
    Directory? dir = File(Platform.resolvedExecutable).parent;
    dir != null && dir.path != dir.parent.path;
    dir = dir.parent
  ) {
    final candidate = Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidate.existsSync()) {
      fontsDir = candidate;
      break;
    }
  }
  if (fontsDir == null) return false;

  const weights = {
    'Roboto-Regular.ttf': FontWeight.w400,
    'Roboto-Medium.ttf': FontWeight.w500,
    'Roboto-Bold.ttf': FontWeight.w700,
    'Roboto-Black.ttf': FontWeight.w900,
  };
  final loader = FontLoader('Roboto');
  var found = 0;
  for (final entry in weights.entries) {
    final file = File('${fontsDir.path}/${entry.key}');
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    found++;
  }
  if (found == 0) return false;
  await loader.load();
  return true;
}
