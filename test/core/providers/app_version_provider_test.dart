import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:app/core/providers/app_version_provider.dart';

void main() {
  test('reads the installed version and build number', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Marilin',
      packageName: 'com.marilin.app',
      version: '1.4.2',
      buildNumber: '17',
      buildSignature: '',
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(appVersionProvider.future), '1.4.2 (17)');
  });
}
