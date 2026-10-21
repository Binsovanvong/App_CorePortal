import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/token_store.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/routes/apppage.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/screens/login/login_controller.dart';
import 'package:core_portal/screens/update_password/update_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempFontDir;

  setUpAll(() async {
    Get.testMode = true;
    tempFontDir = Directory.systemTemp.createTempSync('google_fonts_test');
    final fontFile = File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
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
        File('${tempFontDir.path}/$name').writeAsBytesSync(fontBytes);
      }
    }

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempFontDir.path;
    });
    await GetStorage.init();
  });

  tearDownAll(() async {
    try {
      tempFontDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ApiClient.logout();
    Get.reset();
    Get.testMode = true;
  });

  Widget buildTestApp(Widget home) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      getPages: [
        GetPage(name: AppRoutes.login, page: () => const Scaffold(body: Text('Login Screen'))),
        GetPage(name: AppRoutes.mainPage, page: () => const Scaffold(body: Text('Home Screen'))),
        GetPage(
          name: AppRoutes.updatePassword,
          page: () {
            final args = Get.arguments;
            final ticket = (args is Map ? args['ticket'] : null)?.toString() ?? '';
            final username = (args is Map ? args['username'] : null)?.toString();
            final rawExpires = args is Map ? (args['expires_in'] ?? args['expiresIn']) : null;
            final expiresIn = rawExpires is int ? rawExpires : int.tryParse(rawExpires?.toString() ?? '');
            return UpdatePasswordScreen(ticket: ticket, username: username, expiresIn: expiresIn);
          },
        ),
      ],
      home: home,
    );
  }

  group('Expired-Password Flow Tests', () {
    testWidgets('1. Navigation from Login: 409 update_password_required navigates to UpdatePasswordScreen without first_login flag and clears password from memory', (tester) async {
      final dio = ApiClient.refreshApi;
      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/api/mobile/auth/login') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 409,
                data: {
                  'detail': {
                    'code': 'update_password_required',
                    'required_action': 'UPDATE_PASSWORD',
                    'ticket': 'test-one-time-ticket-12345',
                    'expires_in': 180,
                    'update_password_endpoint': '/api/mobile/auth/update-password',
                  }
                },
              ),
            );
            return;
          }
          handler.next(options);
        },
      );
      dio.interceptors.insert(0, testInterceptor);

      try {
        final controller = Get.put(LoginController());
        controller.usernameController.text = 'alice';
        controller.passwordController.text = 'ExpiredSecret123!';

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            getPages: AppPages.routes,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => controller.loginWithCredentials(context),
                  child: const Text('Login'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        // Password must be cleared from memory immediately
        expect(controller.passwordController.text, isEmpty);

        // Never persist ticket into unencrypted storage
        final box = GetStorage();
        expect(box.read('ticket'), isNull);
        expect(box.read('test-one-time-ticket-12345'), isNull);

        // Should have navigated to UpdatePasswordScreen
        expect(find.byType(UpdatePasswordScreen), findsOneWidget);
        expect(find.text('Update your password'), findsOneWidget);
        expect(find.text('Your password has expired or must be changed before you can continue.'), findsOneWidget);
      } finally {
        dio.interceptors.remove(testInterceptor);
        Get.delete<LoginController>();
      }
    });

    testWidgets('2. UI & Inline Validation: Displays guidelines, enforces password policy, shows mismatch error, and disables submit button while invalid', (tester) async {
      final testDio = Dio();

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'mem-ticket-xyz',
            username: 'alice',
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // UI Title and Message requirements
      expect(find.text('Update your password'), findsOneWidget);
      expect(find.text('Your password has expired or must be changed before you can continue.'), findsOneWidget);

      // Guidance card visible
      expect(find.textContaining('New password must be at least 8 characters long'), findsOneWidget);
      expect(find.textContaining('Must include uppercase, lowercase, numbers, and special characters'), findsOneWidget);

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitButton = find.byKey(const Key('update_password_submit_button'));

      expect(newPwdField, findsOneWidget);
      expect(confirmPwdField, findsOneWidget);
      expect(submitButton, findsOneWidget);

      // Initially submit button is disabled
      ElevatedButton btn = tester.widget(submitButton);
      expect(btn.onPressed, isNull);

      // Enter password that is too short
      await tester.enterText(newPwdField, 'Short1!');
      await tester.enterText(confirmPwdField, 'Short1!');
      await tester.pump();
      btn = tester.widget(submitButton);
      expect(btn.onPressed, isNull); // Still disabled (<8 chars)

      // Enter password that contains username
      await tester.enterText(newPwdField, 'AliceSecret123!');
      await tester.enterText(confirmPwdField, 'AliceSecret123!');
      await tester.pump();
      btn = tester.widget(submitButton);
      expect(btn.onPressed, isNull); // Still disabled (contains username)

      // Enter valid password in new, but mismatched confirm password
      await tester.enterText(newPwdField, 'ValidSecret123!');
      await tester.enterText(confirmPwdField, 'Mismatched123!');
      await tester.pump();

      // Confirmation mismatch inline validation error must be displayed
      expect(find.text('New password and confirm password do not match'), findsOneWidget);
      btn = tester.widget(submitButton);
      expect(btn.onPressed, isNull); // Disabled while mismatched

      // Enter matching confirm password
      await tester.enterText(confirmPwdField, 'ValidSecret123!');
      await tester.pump();

      // Mismatch error must disappear
      expect(find.text('New password and confirm password do not match'), findsNothing);
      btn = tester.widget(submitButton);
      expect(btn.onPressed, isNotNull); // Button is now enabled!

      // Test show/hide password toggle controls
      final newPwdWidgetBefore = tester.widget<TextField>(newPwdField);
      expect(newPwdWidgetBefore.obscureText, isTrue);

      final visibilityToggles = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityToggles, findsNWidgets(2));

      await tester.tap(visibilityToggles.first);
      await tester.pump();

      final newPwdWidgetAfter = tester.widget<TextField>(newPwdField);
      expect(newPwdWidgetAfter.obscureText, isFalse);
    });

    testWidgets('3. Success Handling: Submits ticket and passwords, saves tokens securely, clears memory, and navigates to home', (tester) async {
      final testDio = Dio();
      Map<String, dynamic>? submittedBody;

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/mobile/auth/update-password') {
              submittedBody = options.data as Map<String, dynamic>;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'access_token': 'new_jwt_access_token_123',
                    'refresh_token': 'new_jwt_refresh_token_456',
                    'expires_in': 3600,
                  },
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'one-time-ticket-success',
            username: 'bob',
            expiresIn: 0,
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitBtnFinder = find.byKey(const Key('update_password_submit_button'));

      await tester.enterText(newPwdField, 'FreshPassword2026!');
      await tester.enterText(confirmPwdField, 'FreshPassword2026!');
      await tester.pump();

      await tester.tap(submitBtnFinder);
      await tester.pumpAndSettle();

      // Check request payload sent over wire
      expect(submittedBody, isNotNull);
      expect(submittedBody!['ticket'], equals('one-time-ticket-success'));
      expect(submittedBody!['new_password'], equals('FreshPassword2026!'));
      expect(submittedBody!['confirm_password'], equals('FreshPassword2026!'));

      // Check token storage: access_token and refresh_token saved into secure storage
      final tokenStore = TokenStore(const FlutterSecureStorage());
      final savedAccess = await tokenStore.accessToken;
      final savedRefresh = await tokenStore.refreshToken;
      expect(savedAccess, equals('new_jwt_access_token_123'));
      expect(savedRefresh, equals('new_jwt_refresh_token_456'));

      // Navigated to Home screen
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('4. Expired Ticket Handling: Server HTTP 401 clears ticket and returns to Login', (tester) async {
      final testDio = Dio();

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/mobile/auth/update-password') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 401,
                    data: {
                      'detail': {
                        'code': 'ticket_expired',
                        'message': 'Your password-change session has expired. Please sign in again.',
                      }
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'expired-ticket-test',
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitBtnFinder = find.byKey(const Key('update_password_submit_button'));

      await tester.enterText(newPwdField, 'ComplexPass123!');
      await tester.enterText(confirmPwdField, 'ComplexPass123!');
      await tester.pump();

      await tester.tap(submitBtnFinder);
      await tester.pumpAndSettle();

      // Navigated back to Login screen
      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('5. Client Expiry: Ticket timeout expires session, clears ticket, and returns to Login', (tester) async {
      final testDio = Dio();

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'short-lived-ticket',
            expiresIn: 1, // 1 second
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify on UpdatePasswordScreen initially
      expect(find.byType(UpdatePasswordScreen), findsOneWidget);

      // Fast-forward time past 1 second expiration
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should automatically navigate back to Login Screen
      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('6. Rejected Password: HTTP 400 password_rejected displays server message and requires signing in again', (tester) async {
      final testDio = Dio();

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/mobile/auth/update-password') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 400,
                    data: {
                      'detail': {
                        'code': 'password_rejected',
                        'message': 'Password was used previously. Choose a different one.',
                      }
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'consumed-ticket-123',
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitBtnFinder = find.byKey(const Key('update_password_submit_button'));

      await tester.enterText(newPwdField, 'MyOldPassword123!');
      await tester.enterText(confirmPwdField, 'MyOldPassword123!');
      await tester.pump();

      await tester.tap(submitBtnFinder);
      await tester.pumpAndSettle();

      // Navigated back to login because ticket was consumed by Keycloak
      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('7. Network Uncertainty: Connection timeout does not retry, returns to login advising user to try new password', (tester) async {
      final testDio = Dio();
      int submissionAttempts = 0;

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/mobile/auth/update-password') {
              submissionAttempts++;
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionTimeout,
                  error: 'Connection timeout',
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'timeout-ticket-123',
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitBtnFinder = find.byKey(const Key('update_password_submit_button'));

      await tester.enterText(newPwdField, 'SecurePassword123!');
      await tester.enterText(confirmPwdField, 'SecurePassword123!');
      await tester.pump();

      await tester.tap(submitBtnFinder);
      await tester.pumpAndSettle();

      // Exactly 1 attempt made (never automatically retries)
      expect(submissionAttempts, equals(1));

      // Returned to login screen
      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('8. HTTP 429 Rate Limiting: Displays too many attempts message without kicking user to login', (tester) async {
      final testDio = Dio();

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/mobile/auth/update-password') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 429,
                    data: {
                      'detail': 'Too many attempts. Please wait and try again.',
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'rate-limited-ticket',
            expiresIn: 0,
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitBtnFinder = find.byKey(const Key('update_password_submit_button'));

      await tester.enterText(newPwdField, 'SecurePassword123!');
      await tester.enterText(confirmPwdField, 'SecurePassword123!');
      await tester.pump();

      await tester.tap(submitBtnFinder);
      await tester.pumpAndSettle();

      // Remains on UpdatePasswordScreen so user can wait and retry
      expect(find.byType(UpdatePasswordScreen), findsOneWidget);
      expect(find.text('Login Screen'), findsNothing);
    });

    testWidgets('9. HTTP 409 Unsupported Action: Redirects to login/support', (tester) async {
      final testDio = Dio();

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/mobile/auth/update-password') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 409,
                    data: {
                      'detail': {
                        'code': 'another_action_required',
                        'message': 'Account requires another action.',
                      }
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'action-required-ticket',
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newPwdField = find.byKey(const Key('update_new_password_field'));
      final confirmPwdField = find.byKey(const Key('update_confirm_password_field'));
      final submitBtnFinder = find.byKey(const Key('update_password_submit_button'));

      await tester.enterText(newPwdField, 'SecurePassword123!');
      await tester.enterText(confirmPwdField, 'SecurePassword123!');
      await tester.pump();

      await tester.tap(submitBtnFinder);
      await tester.pumpAndSettle();

      // Redirected to Login screen
      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('10. User Cancellation: Tapping cancel clears in-memory ticket and returns to Login', (tester) async {
      final testDio = Dio();

      await tester.pumpWidget(
        buildTestApp(
          UpdatePasswordScreen(
            ticket: 'cancel-test-ticket',
            dio: testDio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancelBtnFinder = find.byKey(const Key('update_password_cancel_button'));
      expect(cancelBtnFinder, findsOneWidget);

      await tester.tap(cancelBtnFinder);
      await tester.pumpAndSettle();

      // Returned to Login Screen
      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });
  });
}
