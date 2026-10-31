import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// S7 (field test 3): the driver app runs in portrait only; a tilt must not
/// rotate the forms to landscape.
void main() {
  test('the Android activity is locked to portrait', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:screenOrientation="portrait"'));
  });

  test('the iOS app only supports portrait on phones', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final phone = RegExp(
      r'<key>UISupportedInterfaceOrientations</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);

    expect(phone, isNotNull);
    expect(phone!.group(1), contains('UIInterfaceOrientationPortrait'));
    expect(phone.group(1), isNot(contains('Landscape')));
  });
}
