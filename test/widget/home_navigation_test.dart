import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/shared/models/models.dart';

void main() {
  testWidgets(
    'Home opens Search and supports both swipe directions in dark mode',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      var loads = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(
              (ref) async => (
                scope: 'selectedProperty:user:org',
                organizationId: 'org',
                propertyId: null,
              ),
            ),
            propertiesProvider.overrideWith(
              (ref) async => const [
                Property(
                  id: 'one',
                  name: 'Hillside House',
                  type: 'PG',
                  city: 'Pune',
                ),
                Property(
                  id: 'two',
                  name: 'Lake View',
                  type: 'PG',
                  city: 'Mumbai',
                ),
              ],
            ),
            dashboardProvider.overrideWith((ref) async {
              loads++;
              return {
                'financial': {'todayCollectedPaise': 5000},
              };
            }),
          ],
          child: const PgInfoApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search anything'));
      await tester.pumpAndSettle();
      expect(find.text('Search across PgInfo'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      final before = loads;
      await tester.drag(find.byType(ListView).first, const Offset(0, 325));
      await tester.pumpAndSettle();
      expect(loads, before + 1);

      await tester.drag(find.byType(ListView).first, const Offset(280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Search properties'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'mumbai');
      await tester.pumpAndSettle();
      expect(find.text('Hillside House'), findsNothing);
      expect(find.text('Lake View'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Search anything'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Profile & settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
