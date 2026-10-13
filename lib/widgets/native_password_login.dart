import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Standalone Flutter login & update-password widget for Keycloak native onboarding.
/// Mount in the app's login route. onAuthenticated must persist tokens using
/// Keychain/Keystore secure storage and enter the authenticated app.
class NativePasswordLogin extends StatefulWidget {
  const NativePasswordLogin({
    super.key,
    required this.apiBase,
    required this.client,
    required this.onAuthenticated,
  });

  final Uri apiBase;
  final http.Client client;
  final Future<void> Function(Map<String, dynamic> tokens) onAuthenticated;

  @override
  State<NativePasswordLogin> createState() => _NativePasswordLoginState();
}

class _NativePasswordLoginState extends State<NativePasswordLogin> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _ticket;
  String? _message;
  DateTime? _expiresAt;
  Timer? _expiryTimer;
  bool _busy = false;

  void _clearTicket() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _ticket = null;
    _expiresAt = null;
    _newPassword.clear();
    _confirmPassword.clear();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final changing = _ticket != null;
    if (changing &&
        (_expiresAt == null || !DateTime.now().isBefore(_expiresAt!))) {
      setState(() {
        _clearTicket();
        _message = 'Your password-change session expired. Sign in again.';
      });
      return;
    }
    if (changing &&
        (_newPassword.text.isEmpty ||
            _newPassword.text != _confirmPassword.text)) {
      setState(() => _message = 'Enter matching new passwords.');
      return;
    }
    if (!changing && (_username.text.trim().isEmpty || _password.text.isEmpty)) {
      setState(() => _message = 'Enter your username and password.');
      return;
    }
    final body = changing
        ? {
            'ticket': _ticket!,
            'new_password': _newPassword.text,
            'confirm_password': _confirmPassword.text,
          }
        : {'username': _username.text.trim(), 'password': _password.text};

    // Drop credentials from controllers before awaiting a network operation.
    _password.clear();
    if (changing) _clearTicket();
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if ((widget.apiBase.scheme != 'https' && widget.apiBase.scheme != 'http') ||
          widget.apiBase.userInfo.isNotEmpty) {
        throw StateError('The authentication API must use a valid HTTP/HTTPS scheme.');
      }
      final base = widget.apiBase.toString().replaceFirst(RegExp(r'/+$'), '');
      final path = changing ? 'update-password' : 'login';
      final request =
          http.Request('POST', Uri.parse('$base/api/mobile/auth/$path'))
            ..followRedirects = false
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            })
            ..body = jsonEncode(body);

      final response = await (() async {
        final streamed = await widget.client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 45));

      if (!mounted) return;
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const FormatException();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();

      if (response.statusCode == 200) {
        if (decoded['access_token'] is! String ||
            (decoded['access_token'] as String).isEmpty) {
          throw const FormatException();
        }
        _clearTicket();
        await widget.onAuthenticated(decoded);
        return;
      }

      final detail = decoded['detail'];
      final detailMap = (detail is Map)
          ? detail
          : (decoded is Map ? decoded : null);
      final code = (detailMap?['code'] ?? decoded['code'] ?? '').toString();
      final reqAction =
          (detailMap?['required_action'] ?? decoded['required_action'] ?? '')
              .toString()
              .toUpperCase();

      if (!changing &&
          response.statusCode == 409 &&
          (code == 'update_password_required' || reqAction == 'UPDATE_PASSWORD')) {
        final ticket = (detailMap?['ticket'] ?? decoded['ticket'])?.toString();
        final rawSeconds = detailMap?['expires_in'] ?? decoded['expires_in'];
        final seconds = rawSeconds is int
            ? rawSeconds
            : (int.tryParse(rawSeconds?.toString() ?? '') ?? 180);
        if (ticket != null && ticket.isNotEmpty && seconds > 0) {
          setState(() {
            _ticket = ticket;
            _expiresAt = DateTime.now().add(Duration(seconds: seconds));
            _message = 'Choose a new password to finish signing in.';
          });
          _expiryTimer = Timer(Duration(seconds: seconds), () {
            if (!mounted) return;
            setState(() {
              _clearTicket();
              _message = 'Your password-change session expired. Sign in again.';
            });
          });
          return;
        }
      }

      setState(() {
        _message = detail is Map && detail['message'] is String
            ? detail['message'] as String
            : detail is String
                ? detail
                : 'Unable to sign in. Please try again.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = changing
            ? 'The update could not be confirmed. Try signing in with your new password.'
            : 'Unable to sign in. Please try again.');
      }
    } finally {
      body.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _username.dispose();
    _password.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final changing = _ticket != null;
    return Scaffold(
      appBar: AppBar(title: Text(changing ? 'Update Password' : 'Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!changing) ...[
            TextField(
              controller: _username,
              enabled: !_busy,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ] else ...[
            TextField(
              controller: _newPassword,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              controller: _confirmPassword,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_message!),
            ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              _busy
                  ? 'Please wait…'
                  : changing
                      ? 'Update and sign in'
                      : 'Sign in',
            ),
          ),
          if (changing)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _clearTicket();
                        _message = null;
                      }),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}
