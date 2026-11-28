import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/design_system/theme.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/all/presentation/action_screen.dart';

class _ReceiptRepository extends PgRepository {
  _ReceiptRepository() : super(ApiClient(const FlutterSecureStorage()));
  int requests = 0;

  @override
  Future<Map<String, dynamic>> receipt(String id) async {
    requests++;
    return {
      'receiptNumber': 'RCP-2026-1234',
      'amountPaise': 150050,
      'amountFormatted': '₹1,500.50',
      'mode': 'RAZORPAY',
      'collectionDate': '2026-11-23T00:00:00.000Z',
      'reference': 'pay_fixture',
      'refundedAmountPaise': 10050,
      'refundedAmountFormatted': '₹100.50',
      'resident': {
        'name': 'Example Tenant',
        'mobile': '9876543210',
        'property': 'Example Accommodation',
      },
      'allocations': [
        {
          'type': 'RENT',
          'description': 'November rent',
          'amountFormatted': '₹1,500.50',
        },
      ],
    };
  }
}

void main() {
  testWidgets('receipts copy display data without tenant phone or raw fields', (
    tester,
  ) async {
    final repository = _ReceiptRepository();
    String? clipboard;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: PgTheme.build(Brightness.dark),
          home: const ActionScreen(
            name: 'receipt',
            query: {'id': 'payment-fixture'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Receipt RCP-2026-1234'), findsOneWidget);
    final copy = find.text('Copy receipt details');
    await tester.scrollUntilVisible(
      copy,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(clipboard, contains('Example Accommodation'));
    expect(clipboard, contains('₹1,500.50'));
    expect(clipboard, contains('pay_fixture'));
    expect(clipboard, contains('Refunded: ₹100.50'));
    expect(clipboard, isNot(contains('9876543210')));
    expect(repository.requests, 1);
  });
}
