import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/di/providers.dart';
import '../../core/network/api_client.dart';

typedef MoneyRow = Map<String, dynamic>;
final moneyNowProvider = Provider<DateTime>((ref) => DateTime.now());
String moneyAmount(num paise) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: paise % 100 == 0 ? 0 : 2,
).format(paise / 100);

MoneyRow moneyMap(dynamic value) => Map<String, dynamic>.from(value as Map);
int moneyInt(dynamic value) => (value as num?)?.toInt() ?? 0;
String moneyName(MoneyRow r) =>
    '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim();
String moneyRoom(MoneyRow r) =>
    'Room ${r['room']?['roomNumber'] ?? '—'} · Bed ${r['bed']?['bedNumber'] ?? '—'}';

/// Canonical, immutable query keys prevent cache misses caused by map identity.
class MoneyQuery {
  MoneyQuery(this.path, [Map<String, String> params = const {}])
    : encoded = jsonEncode(
        Map.fromEntries(
          params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
      );
  final String path, encoded;
  Map<String, dynamic> get params => moneyMap(jsonDecode(encoded));
  @override
  bool operator ==(Object other) =>
      other is MoneyQuery && path == other.path && encoded == other.encoded;
  @override
  int get hashCode => Object.hash(path, encoded);
}

class MoneyPage {
  const MoneyPage(
    this.items,
    this.page,
    this.hasMore,
    this.total, {
    this.loadingMore = false,
    this.appendError,
  });
  final List<MoneyRow> items;
  final int page, total;
  final bool hasMore, loadingMore;
  final Object? appendError;
}

final moneyFeedProvider = AsyncNotifierProvider.autoDispose
    .family<MoneyFeed, MoneyPage, MoneyQuery>(MoneyFeed.new);

class MoneyFeed extends AsyncNotifier<MoneyPage> {
  MoneyFeed(this.query);
  final MoneyQuery query;
  Object generation = Object();
  CancelToken? token;
  @override
  Future<MoneyPage> build() async {
    ref.watch(selectedOrganizationProvider);
    final api = ref.watch(apiClientProvider);
    generation = Object();
    token?.cancel();
    final currentToken = token = CancelToken();
    ref.onDispose(() => currentToken.cancel());
    return fetch(api, 1, currentToken);
  }

  Future<MoneyPage> fetch(ApiClient api, int page, CancelToken cancel) async {
    final raw = moneyMap(
      await api.get(
        query.path,
        query: {...query.params, 'page': page, 'limit': 20},
        cancelToken: cancel,
      ),
    );
    final meta = moneyMap(raw['meta']);
    return MoneyPage(
      (raw['data'] as List).map(moneyMap).toList(),
      page,
      meta['hasMore'] == true,
      moneyInt(meta['total']),
    );
  }

  Future<void> loadMore() async {
    final old = state.asData?.value;
    if (old == null || old.loadingMore || !old.hasMore) return;
    final requestGeneration = generation;
    state = AsyncData(
      MoneyPage(old.items, old.page, old.hasMore, old.total, loadingMore: true),
    );
    try {
      final next = await fetch(
        ref.read(apiClientProvider),
        old.page + 1,
        token!,
      );
      if (!ref.mounted || !identical(generation, requestGeneration)) return;
      final byId = {
        for (final row in old.items) row['id']: row,
        for (final row in next.items) row['id']: row,
      };
      state = AsyncData(
        MoneyPage(byId.values.toList(), next.page, next.hasMore, next.total),
      );
    } catch (e) {
      if (ref.mounted && identical(generation, requestGeneration)) {
        state = AsyncData(
          MoneyPage(
            old.items,
            old.page,
            old.hasMore,
            old.total,
            appendError: e,
          ),
        );
      }
    }
  }
}

final moneyObjectProvider = FutureProvider.autoDispose
    .family<MoneyRow, MoneyQuery>((ref, q) async {
      ref.watch(selectedOrganizationProvider);
      final cancel = CancelToken();
      ref.onDispose(() => cancel.cancel());
      return moneyMap(
        await ref
            .watch(apiClientProvider)
            .get(q.path, query: q.params, cancelToken: cancel),
      );
    });

final moneyOptionsProvider = FutureProvider.autoDispose
    .family<List<MoneyRow>, String>((ref, path) async {
      ref.watch(selectedOrganizationProvider);
      final cancel = CancelToken();
      ref.onDispose(() => cancel.cancel());
      final data = await ref
          .watch(apiClientProvider)
          .get(path, cancelToken: cancel);
      return (data as List).map(moneyMap).toList();
    });

void refreshMoney(WidgetRef ref) {
  ref.invalidate(moneyFeedProvider);
  ref.invalidate(moneyObjectProvider);
  ref.invalidate(moneyOptionsProvider);
  ref.invalidate(pagedListProvider);
  ref.invalidate(tenantLedgerProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardPeriodProvider);
  ref.invalidate(payoutAccountsProvider);
  ref.invalidate(optionsProvider);
}

const dueCategories = [
  'Rent',
  'Deposit',
  'Electricity',
  'Water',
  'Internet',
  'Food',
  'Housekeeping',
  'Laundry',
  'Maintenance',
  'Repair',
  'Late Fine',
  'Damage Fine',
  'Key Charges',
  'Parking',
  'Common Areas',
  'KYC',
  'Agreement',
  'Move-out Charges',
];
const paymentModes = ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'OTHER'];
const expenseCategories = [
  'EMI',
  'Groceries',
  'Salary',
  'Electrical Appliances',
  'Services',
  'Other',
  'Travel & Fuel',
  'Insurance Premium',
  'Loan EMI',
  'Maintenance',
  'Cleaning',
  'Tax',
];
