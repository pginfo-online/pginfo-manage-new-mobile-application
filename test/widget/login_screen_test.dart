import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/authentication/presentation/login_screen.dart';

void main() {
  testWidgets('registration exposes the required workspace fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    expect(find.text('Welcome to PgInfo'), findsOneWidget);
    await tester.tap(find.text('New to PgInfo? Create account'));
    await tester.pump();
    expect(find.text('Organization name'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
  });
}
