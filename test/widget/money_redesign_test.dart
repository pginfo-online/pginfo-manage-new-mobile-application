import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/design_system/theme.dart';
import 'package:mobile/features/money/money_data.dart';
import 'package:mobile/features/money/presentation/money_screen.dart';
import 'package:mobile/features/money/presentation/money_forms.dart';
import 'package:mobile/features/money/presentation/money_widgets.dart';
import 'package:mobile/shared/models/models.dart';

final tenant = <String, dynamic>{
  'id': 'tenant-1',
  'firstName': 'Madhav',
  'lastName': 'Sharma',
  'mobile': '9876543210',
  'property': {'name': 'Vanalilka'},
  'room': {'roomNumber': '101'},
  'bed': {'bedNumber': 'B'},
};
final due = <String, dynamic>{
  'id': 'tenant-1',
  'resident': tenant,
  'outstanding': 1200000,
  'overdueDays': 3,
  'dueDate': '2026-11-06T00:00:00.000Z',
};

class MoneyFakeApi extends ApiClient {
  MoneyFakeApi() : super(const FlutterSecureStorage());
  int calls = 0;
  bool failMore = false;
  Completer<dynamic>? pending;
  final posts = <({String path, Map<String, dynamic> body})>[];
  @override
  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    posts.add((path: path, body: data));
    return {
      'whatsapp': {'accepted': 1},
      'email': {'accepted': 0},
      'failedCount': 0,
    };
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    calls++;
    if (pending != null) return pending!.future;
    if (path.endsWith('/summary')) {
      return {
        'allDues': 1200000,
        'currentDues': 1200000,
        'monthDues': 1200000,
        'unpaidRent': 1000000,
      };
    }
    if (path.endsWith('/payment-context')) {
      return {
        'resident': tenant,
        'totalDues': 1200000,
        'offer': null,
        'bills': [
          {
            'id': 'bill-1',
            'type': 'RENT',
            'amount': 1000000,
            'paidAmount': 0,
            'dueDate': '2026-11-06',
          },
          {
            'id': 'bill-2',
            'type': 'ELECTRICITY',
            'amount': 200000,
            'paidAmount': 0,
            'dueDate': '2026-11-06',
          },
        ],
      };
    }
    if (path.endsWith('/categories')) {
      return [
        {'id': 'category-1', 'name': 'Salary'},
      ];
    }
    if (path.endsWith('/reminder')) {
      return {
        'resident': tenant,
        'totalDues': 1200000,
        'paymentLink': null,
        'message': 'Hello Madhav, your outstanding dues are ₹12,000.',
      };
    }
    final page = query?['page'] ?? 1;
    if (page == 2 && failMore) throw const ApiFailure('Connection lost', null);
    return {
      'data': path.endsWith('/dues') ? [due] : <dynamic>[],
      'meta': {'total': 2, 'hasMore': page == 1},
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File('test/fonts/${font.value}').readAsBytes(),
            ),
          ),
        );
      await loader.load();
    }
  });
  test('query keys are independent of parameter insertion order', () {
    expect(
      MoneyQuery('/dues', {'a': '1', 'b': '2'}),
      MoneyQuery('/dues', {'b': '2', 'a': '1'}),
    );
  });
  test(
    'pagination follows metadata and preserves rows after a failed append',
    () async {
      final api = MoneyFakeApi();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final q = MoneyQuery('/money/dues');
      final sub = container.listen(moneyFeedProvider(q), (_, _) {});
      addTearDown(sub.close);
      final first = await container.read(moneyFeedProvider(q).future);
      expect(first.items, hasLength(1));
      expect(first.hasMore, isTrue);
      api.failMore = true;
      await container.read(moneyFeedProvider(q).notifier).loadMore();
      var page = container.read(moneyFeedProvider(q)).requireValue;
      expect(page.items, hasLength(1));
      expect(page.appendError, isNotNull);
      expect(page.page, 1);
      api.failMore = false;
      await container.read(moneyFeedProvider(q).notifier).loadMore();
      page = container.read(moneyFeedProvider(q)).requireValue;
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
      expect(page.page, 2);
    },
  );
  Future<void> render(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MoneyFakeApi()),
          moneyNowProvider.overrideWithValue(DateTime(2026, 11, 9)),
          propertiesProvider.overrideWith(
            (ref) async => [
              const Property(id: 'property-1', name: 'Vanalilka', type: 'PG'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: PgTheme.build(Brightness.light),
          home: RepaintBoundary(key: const ValueKey('screen'), child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'six money tabs render and dues expose accessible quick actions',
    (tester) async {
      await render(tester, const MoneyScreen());
      for (final label in [
        'Due Packages',
        'Dues',
        'Collection',
        'Expense',
        'Report',
        'Bank',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Dues'));
      await tester.pumpAndSettle();
      expect(find.text('Madhav Sharma'), findsOneWidget);
      expect(find.text('Record Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('../goldens/money_dues.png'),
      );
      await tester.drag(find.byType(MoneyDueCard), const Offset(-170, 0));
      await tester.pumpAndSettle();
      for (final label in [
        'Give Discount',
        'Add Dues',
        'Remind Parent',
        'Add Remarks',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('../goldens/money_swipe.png'),
      );
    },
  );
  testWidgets('payment form displays tenant, real totals and payment breakup', (
    tester,
  ) async {
    await render(
      tester,
      const RecordMoneyPaymentScreen(residentId: 'tenant-1'),
    );
    expect(find.text('Record Payment'), findsNWidgets(2));
    expect(find.text('Vanalilka'), findsOneWidget);
    expect(find.text('Net Receivable'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('screen')),
      matchesGoldenFile('../goldens/money_payment.png'),
    );
    await tester.tap(find.text('View Breakup ›'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Breakup'), findsOneWidget);
    expect(find.textContaining('ELECTRICITY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced-motion skeleton has semantics and no active animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: MoneySkeleton()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Loading money details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'expense and package screens fit a phone and expose required fields',
    (tester) async {
      await render(tester, const MoneyEditor(kind: 'expense'));
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Paid By'), findsOneWidget);
      expect(find.text('Paid To'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('../goldens/money_expense.png'),
      );
      await render(tester, const MoneyEditor(kind: 'package'));
      expect(find.text('Add Due Package'), findsOneWidget);
      expect(find.text('Billing Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reminder and discount sheets show real tenant details', (
    tester,
  ) async {
    await render(
      tester,
      const Scaffold(
        body: MoneyActionSheet(residentId: 'tenant-1', action: 'Remind to Pay'),
      ),
    );
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Create Payment Link'), findsOneWidget);
    expect(find.text('Madhav Sharma'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('screen')),
      matchesGoldenFile('../goldens/money_reminder.png'),
    );
    await render(
      tester,
      const Scaffold(
        body: MoneyActionSheet(residentId: 'tenant-1', action: 'Give Discount'),
      ),
    );
    expect(find.text('Full Dues'), findsOneWidget);
    expect(find.text('Discount Valid Till'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('screen')),
      matchesGoldenFile('../goldens/money_discount.png'),
    );
  });
  testWidgets('bulk reminders send only the explicitly selected tenant', (
    tester,
  ) async {
    final api = MoneyFakeApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: MaterialApp(home: const MoneyBulkReminderScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send Reminders (1)'));
    await tester.pumpAndSettle();
    expect(api.posts.single.body['residentIds'], ['tenant-1']);
    expect(api.posts.single.path, '/announcements/reminders/rent');
    expect(tester.takeException(), isNull);
  });
}
