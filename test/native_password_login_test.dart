import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:core_portal/widgets/native_password_login.dart';

void main() {
  const validTicket = '1234567890123456789012345678901234567890123'; // 43 chars regex matches ^[A-Za-z0-9_-]{43}$
  final apiBase = Uri.parse('https://api.example.com');

  testWidgets('Successful temporary-password login transitions to update-password form and completes authentication', (tester) async {
    Map<String, dynamic>? authenticatedTokens;
    int loginRequests = 0;
    int updateRequests = 0;

    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/mobile/auth/login') {
        loginRequests++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['username'], 'alice');
        expect(body['password'], 'temp-pass');
        return http.Response(
          jsonEncode({
            'detail': {
              'code': 'update_password_required',
              'required_action': 'UPDATE_PASSWORD',
              'ticket': validTicket,
              'expires_in': 180,
            }
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      } else if (request.url.path == '/api/mobile/auth/update-password') {
        updateRequests++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['ticket'], validTicket);
        expect(body['new_password'], 'NewSecret123!');
        // Confirm password is sent over wire as required by backend OpenAPI schema
        expect(body['confirm_password'], 'NewSecret123!');
        return http.Response(
          jsonEncode({
            'access_token': 'test_access_jwt',
            'refresh_token': 'test_refresh_jwt',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NativePasswordLogin(
          apiBase: apiBase,
          client: mockClient,
          onAuthenticated: (tokens) async {
            authenticatedTokens = tokens;
          },
        ),
      ),
    );

    // Initial state: username and password fields visible
    expect(find.text('Sign in'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    // Enter credentials
    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'temp-pass');

    // Tap Sign in
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(loginRequests, 1);
    // Transistioned to password change form
    expect(find.text('Update Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'New password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm new password'), findsOneWidget);

    // Enter matching new password
    await tester.enterText(find.widgetWithText(TextField, 'New password'), 'NewSecret123!');
    await tester.enterText(find.widgetWithText(TextField, 'Confirm new password'), 'NewSecret123!');

    // Submit update
    await tester.tap(find.widgetWithText(FilledButton, 'Update and sign in'));
    await tester.pumpAndSettle();

    expect(updateRequests, 1);
    expect(authenticatedTokens, isNotNull);
    expect(authenticatedTokens!['access_token'], 'test_access_jwt');
    expect(authenticatedTokens!['refresh_token'], 'test_refresh_jwt');
  });

  testWidgets('Policy rejection consumes ticket and requires fresh sign in attempt', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/mobile/auth/login') {
        return http.Response(
          jsonEncode({
            'detail': {
              'code': 'update_password_required',
              'required_action': 'UPDATE_PASSWORD',
              'ticket': validTicket,
              'expires_in': 180,
            }
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      } else if (request.url.path == '/api/mobile/auth/update-password') {
        return http.Response(
          jsonEncode({
            'detail': {
              'code': 'password_rejected',
              'message': 'Password does not meet the account password policy. Sign in again to retry.',
            }
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NativePasswordLogin(
          apiBase: apiBase,
          client: mockClient,
          onAuthenticated: (_) async {},
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'temp');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Now on update password form
    await tester.enterText(find.widgetWithText(TextField, 'New password'), 'short');
    await tester.enterText(find.widgetWithText(TextField, 'Confirm new password'), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Update and sign in'));
    await tester.pumpAndSettle();

    // Informs user of policy rejection
    expect(find.textContaining('Password does not meet the account password policy'), findsOneWidget);
  });

  testWidgets('Generic required_action never opens password-update form', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/mobile/auth/login') {
        return http.Response(
          jsonEncode({
            'detail': {
              'code': 'required_action',
              'message': 'Complete the account\'s required actions in the browser to sign in.',
            }
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NativePasswordLogin(
          apiBase: apiBase,
          client: mockClient,
          onAuthenticated: (_) async {},
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'temp');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // MUST remain on Sign in, NEVER opening password update fields
    expect(find.text('Sign in'), findsWidgets);
    expect(find.widgetWithText(TextField, 'New password'), findsNothing);
    expect(find.textContaining('Complete the account\'s required actions in the browser'), findsOneWidget);
  });

  testWidgets('Cancellation clears ticket and restores sign in view', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'detail': {
            'code': 'update_password_required',
            'required_action': 'UPDATE_PASSWORD',
            'ticket': validTicket,
            'expires_in': 180,
          }
        }),
        409,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NativePasswordLogin(
          apiBase: apiBase,
          client: mockClient,
          onAuthenticated: (_) async {},
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'temp');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Update Password'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Returns to Sign in view
    expect(find.text('Sign in'), findsWidgets);
    expect(find.widgetWithText(TextField, 'New password'), findsNothing);
  });

  testWidgets('Lost completion response / timeout advises user to sign in with new password without automatic retry', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/mobile/auth/login') {
        return http.Response(
          jsonEncode({
            'detail': {
              'code': 'update_password_required',
              'required_action': 'UPDATE_PASSWORD',
              'ticket': validTicket,
              'expires_in': 180,
            }
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      } else if (request.url.path == '/api/mobile/auth/update-password') {
        // Simulates timeout / network drop
        throw http.ClientException('Connection dropped / timeout');
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NativePasswordLogin(
          apiBase: apiBase,
          client: mockClient,
          onAuthenticated: (_) async {},
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'temp');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'New password'), 'NewSecret123!');
    await tester.enterText(find.widgetWithText(TextField, 'Confirm new password'), 'NewSecret123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Update and sign in'));
    await tester.pumpAndSettle();

    // Must advise trying the new password
    expect(find.textContaining('The update could not be confirmed. Try signing in with your new password.'), findsOneWidget);
  });
}
