import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry/sentry.dart';

import 'app/app.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const _environment = String.fromEnvironment(
  'APP_ENVIRONMENT',
  defaultValue: 'development',
);

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  void app() => runApp(const ProviderScope(child: PgInfoApp()));

  if (_sentryDsn.isNotEmpty) {
    await Sentry.init((options) {
      options
        ..dsn = _sentryDsn
        ..environment = _environment
        ..sendDefaultPii = false
        ..tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
    }, appRunner: app);
    return;
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled platform error: $error\n$stack');
    return true;
  };
  runZonedGuarded(app, (error, stack) {
    debugPrint('Unhandled asynchronous error: $error\n$stack');
  });
}
