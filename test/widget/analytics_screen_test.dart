import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/design_system/theme.dart';
import 'package:mobile/features/analytics/presentation/analytics_screen.dart';
import 'package:mobile/shared/models/models.dart';

class _DashboardRepository extends PgRepository {
  _DashboardRepository() : super(ApiClient(const FlutterSecureStorage()));

  @override
  Future<({List<Property> items, bool hasMore})> dashboardProperties(
    String search,
    int page,
  ) async => (
    items: search.isEmpty
        ? [const Property(id: 'property-1', name: 'Vanaliika', type: 'PG')]
        : <Property>[],
    hasMore: false,
  );

  @override
  Future<Map<String, dynamic>> dashboard(
    String? propertyId, {
    int? month,
    int? year,
    bool fy = false,
  }) async => {
    'operational': {
      'totalBeds': 12,
      'occupiedBeds': 4,
      'availableBeds': 8,
      'occupancyRate': 33,
      'activeTenants': 4,
      'totalRooms': 6,
      'periodComplaintsCreated': 1,
    },
    'financial': {
      'todayCollectedPaise': 0,
      'monthCollectedPaise': 2000,
      'totalCollectedPaise': 2000,
      'outstandingBalancePaise': 5000,
      'collectionBreakdown': [
        {'dimension': 'Category', 'label': 'RENT', 'amountPaise': 2000},
      ],
    },
  };
}

void main() {
  testWidgets(
    'analytics shows property cards, section tabs, and closable details',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWith((ref) => _DashboardRepository()),
          ],
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Show combined summary'), findsOneWidget);
      expect(find.text('Vanaliika'), findsOneWidget);

      await tester.tap(find.text('Financials'));
      await tester.pumpAndSettle();
      expect(find.text('Dues Overview'), findsOneWidget);
      await tester.tap(find.text('View all ›').first);
      await tester.pumpAndSettle();
      expect(find.text('All-time dues'), findsWidgets);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing);
      await tester.drag(find.byType(TabBarView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Occupancy Status'), findsOneWidget);
    },
  );
  testWidgets('analytics keeps its dark theme at phone size with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWith((ref) => _DashboardRepository()),
        ],
        child: MaterialApp(
          theme: PgTheme.build(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.35)),
            child: child!,
          ),
          home: const AnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, PgTheme.darkCanvas);
    expect(find.text('Vanaliika'), findsOneWidget);
    await tester.drag(find.byType(TabBarView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Dues Overview'), findsOneWidget);
    final filters = find
        .ancestor(
          of: find.text('Dues').first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(filters, const Offset(-248, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Collections'));
    await tester.pumpAndSettle();
    expect(find.text('Collection Overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
