import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/services/app_lock_service.dart';
import 'package:core_portal/widgets/app_lock_overlay.dart';
import 'package:core_portal/widgets/biometric_lock_screen_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = Directory.systemTemp.createTempSync('app_lock_test');
    final fontFile =
        File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
    if (fontFile.existsSync()) {
      final fontBytes = fontFile.readAsBytesSync();
      final fontNames = [
        'KantumruyPro_regular_a43f29e793b554abd46f7b17ea4e024d31e4e66b46d82fbe9cdb2f3490ecbfc7.ttf',
        'KantumruyPro_500_d6a13f77034f52ced78b80437b1a61da765ed4559a0a59c778faa4b01ec12647.ttf',
        'KantumruyPro_600_e49bc2a253cff8663b397c50189fc753fe3f87078d2d4f56c7e9e72d9b116e78.ttf',
        'KantumruyPro_700_55ba36f9e41641f7e5c87dbb8c40afb7e08c5bf52c3bbfa49a76aff022b9c73a.ttf',
        'Poppins_regular_2dd6eb23c4972b346197d272c4e2479b89ed240ece4d2b0e0cd89f0c1caa2710.ttf',
        'Poppins_500_c0ba5609d6562c76ab7db73fa9c9b283d210598cb318a45d4085f540e4753d60.ttf',
        'Poppins_600_ec23e010878cf0841f910ef94f62294e40c7d77ce99be250dba2911d0a1a61cd.ttf',
        'Poppins_700_ed709f2ba2be295030614990104cb4c9c62bc2a2445c25ccb19a1500158a5a8b.ttf',
      ];
      for (final name in fontNames) {
        File('${tempDir.path}/$name').writeAsBytesSync(fontBytes);
      }
    }

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });
    await GetStorage.init();
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ApiClient.logout();
    Get.reset();
  });

  test('AppLockService initializes in unlocked state', () {
    final lockService = Get.put(AppLockService());
    expect(lockService.isLocked.value, isFalse);
    expect(lockService.isAuthenticating.value, isFalse);
  });

  test('shouldLock is false when unauthenticated', () {
    final lockService = Get.put(AppLockService());
    expect(lockService.shouldLock, isFalse);
  });

  testWidgets('AppLockService lifecycle pause locks app when shouldLock is true',
      (tester) async {
    final lockService = Get.put(AppLockService());
    final box = GetStorage();
    box.write('is_logged_in', true);
    box.write('username', 'test_user');
    box.write('biometric_registered_test_user', true);

    expect(lockService.shouldLock, isTrue);

    // Transition to paused/background
    lockService.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    expect(lockService.isLocked.value, isTrue);

    // Clean up
    box.erase();
  });

  testWidgets(
      'AppLockOverlay renders child without red screen and overlays lock screen when locked',
      (tester) async {
    final lockService = Get.put(AppLockService());
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: Text('Protected Screen')),
        builder: (context, child) =>
            AppLockOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );

    expect(find.text('Protected Screen'), findsOneWidget);
    expect(find.byType(BiometricLockScreenView), findsNothing);

    // Trigger lock
    lockService.isLocked.value = true;
    await tester.pump();

    expect(find.byType(BiometricLockScreenView), findsOneWidget);
  });
}
