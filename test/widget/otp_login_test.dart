import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/authentication/presentation/login_screen.dart';

const _mobile = '9876543210';
const _phoneHint = MethodChannel('com.pginfo.manage/phone_number_hint');
const _storage = FlutterSecureStorage();

class _AuthAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int expiresIn = 300;
  int resendAfter = 0;
  bool throttle = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = options.data as Map<String, dynamic>;
    switch (options.path) {
      case '/auth/otp/send':
      case '/auth/otp/resend':
        if (throttle) {
          return _response(429, {
            'title': 'OTP_COOLDOWN',
            'detail': 'Please wait before requesting another code.',
          }, retryAfter: '90');
        }
        return _response(200, {
          'success': true,
          'purpose': data['purpose'],
          'mobile': data['mobile'],
          'maskedMobile': '******3210',
          'expiresInSeconds': expiresIn,
          'resendAfterSeconds': resendAfter,
        });
      case '/auth/otp/login':
        if (data['otp'] != '0123') {
          return _response(401, {
            'title': 'OTP_INVALID',
            'detail': 'Invalid OTP. 4 attempts remaining.',
          });
        }
        return _session(200);
      case '/auth/otp/register':
        return _session(201);
      case '/auth/login':
        return _session(200);
      default:
        throw StateError('Unexpected test request ${options.path}');
    }
  }

  ResponseBody _session(int status) {
    final claims = base64Url.encode(
      utf8.encode(jsonEncode({'sub': 'user-fixture', 'orgId': 'org-fixture'})),
    );
    return _response(status, {
      'tokens': {
        'accessToken': 'header.$claims.signature',
        'refreshToken': 'refresh-fixture',
      },
    });
  }

  ResponseBody _response(
    int status,
    Map<String, Object?> body, {
    String? retryAfter,
  }) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      if (retryAfter != null) 'retry-after': [retryAfter],
    },
  );

  @override
  void close({bool force = false}) {}
}

Future<void> _openLogin(WidgetTester tester, _AuthAdapter adapter) async {
  FlutterSecureStorage.setMockInitialValues({});
  final api = ApiClient(_storage);
  api.dio.httpClientAdapter = adapter;
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Signed in home')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets(
    'SMS login normalizes the phone, resends, and keeps leading zeros',
    (tester) async {
      final adapter = _AuthAdapter();
      await _openLogin(tester, adapter);
      await _tap(tester, 'SMS code');
      await tester.enterText(_field('Mobile number'), '+91 98765-43210');
      await _tap(tester, 'Send code');
      expect(adapter.requests.single.path, '/auth/otp/send');
      expect(adapter.requests.single.data, {
        'mobile': _mobile,
        'purpose': 'LOGIN',
      });
      expect(find.text('Code sent to +91 ******3210'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: _field('4-digit code'),
                matching: find.byType(TextField),
              ),
            )
            .autofillHints,
        contains(AutofillHints.oneTimeCode),
      );
      await _tap(tester, 'Resend code');
      expect(adapter.requests.last.path, '/auth/otp/resend');

      await tester.enterText(_field('4-digit code'), '1111');
      await _tap(tester, 'Verify and sign in');
      expect(find.text('Invalid OTP. 4 attempts remaining.'), findsOneWidget);
      await tester.enterText(_field('4-digit code'), '0123');
      await _tap(tester, 'Verify and sign in');
      expect(adapter.requests.last.data, {'mobile': _mobile, 'otp': '0123'});
      expect(find.text('Signed in home'), findsOneWidget);
      expect(await _storage.read(key: 'refreshToken'), 'refresh-fixture');
    },
  );

  testWidgets('registers with the normalized number selected by the device', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_phoneHint, (call) async {
      expect(call.method, 'requestPhoneNumber');
      return '+91 98765-43210';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(_phoneHint, null));

    final adapter = _AuthAdapter();
    await _openLogin(tester, adapter);
    await _tap(tester, 'New to PgInfo? Create account');
    await _tap(tester, 'SMS code');
    await tester.enterText(_field('Your name'), 'Asha Kulkarni');
    await tester.enterText(_field('Organization name'), 'Asha Properties');
    await _tap(tester, 'Use a number from this device');
    expect(
      tester.widget<TextFormField>(_field('Mobile number')).controller?.text,
      _mobile,
    );
    await _tap(tester, 'Send code');
    expect(adapter.requests.first.data, {
      'mobile': _mobile,
      'purpose': 'REGISTER',
    });
    await tester.enterText(_field('4-digit code'), '0123');
    await _tap(tester, 'Verify and create account');
    expect(adapter.requests.last.path, '/auth/otp/register');
    expect(adapter.requests.last.data, {
      'mobile': _mobile,
      'otp': '0123',
      'firstName': 'Asha',
      'lastName': 'Kulkarni',
      'organizationName': 'Asha Properties',
    });
    expect(find.text('Signed in home'), findsOneWidget);
  });

  testWidgets('uses the server retry header and prevents duplicate sends', (
    tester,
  ) async {
    final adapter = _AuthAdapter()..throttle = true;
    await _openLogin(tester, adapter);
    await _tap(tester, 'SMS code');
    await tester.enterText(_field('Mobile number'), _mobile);
    await _tap(tester, 'Send code');
    final button = find.widgetWithText(FilledButton, 'Try again in 90s');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(adapter.requests, hasLength(1));
    await _tap(tester, 'Password');
  });

  testWidgets(
    'blocks verification after expiry and allows requesting a new code',
    (tester) async {
      final adapter = _AuthAdapter()..expiresIn = 0;
      await _openLogin(tester, adapter);
      await _tap(tester, 'SMS code');
      await tester.enterText(_field('Mobile number'), _mobile);
      await _tap(tester, 'Send code');
      expect(find.text('Code expired'), findsOneWidget);
      final button = find.widgetWithText(FilledButton, 'Verify and sign in');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await _tap(tester, 'Resend code');
      expect(adapter.requests.last.path, '/auth/otp/resend');
    },
  );

  testWidgets(
    'still signs in with email and password through the normal route',
    (tester) async {
      final adapter = _AuthAdapter();
      await _openLogin(tester, adapter);
      await tester.enterText(
        _field('Email or mobile number'),
        'owner@example.test',
      );
      await tester.enterText(_field('Password'), 'ExamplePass1');
      await _tap(tester, 'Sign in');
      expect(adapter.requests.single.path, '/auth/login');
      expect(adapter.requests.single.data, {
        'email': 'owner@example.test',
        'password': 'ExamplePass1',
      });
      expect(find.text('Signed in home'), findsOneWidget);
    },
  );
}
