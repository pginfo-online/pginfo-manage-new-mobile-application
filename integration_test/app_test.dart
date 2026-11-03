import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/features/authentication/presentation/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can enter the registration workflow', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.tap(find.text('New to PgInfo? Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Organization name'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
