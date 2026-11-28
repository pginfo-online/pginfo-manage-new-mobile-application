import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/components/common.dart';
import '../../tenants/presentation/tenant_screens.dart';
import '../money_data.dart';
import 'money_forms.dart';
import 'money_widgets.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 6,
    child: Scaffold(
      appBar: const PgHeader(
        showProperty: true,
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Due Packages'),
            Tab(text: 'Dues'),
            Tab(text: 'Collection'),
            Tab(text: 'Expense'),
            Tab(text: 'Report'),
            Tab(text: 'Bank'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          MoneyTab(kind: 'packages'),
          MoneyTab(kind: 'dues'),
          MoneyTab(kind: 'collections'),
          MoneyTab(kind: 'expenses'),
          MoneyReportsTab(),
          MoneyTab(kind: 'banks'),
        ],
      ),
    ),
  );
}

class MoneyTab extends ConsumerStatefulWidget {
  const MoneyTab({super.key, required this.kind});
  final String kind;
  @override
  ConsumerState<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends ConsumerState<MoneyTab>
    with AutomaticKeepAliveClientMixin {
  String search = '';
  Map<String, String> filters = {};
  Timer? debounce;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  Future<void> filter() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => MoneyFilterScreen(
          values: filters,
          dues: widget.kind == 'dues',
          packages: widget.kind == 'packages',
          expense: widget.kind == 'expenses',
        ),
      ),
    );
    if (result != null && mounted) setState(() => filters = result);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final property = ref.watch(selectedPropertyProvider), kind = widget.kind;
    final paths = {
      'packages': '/money/packages',
      'dues': '/money/dues',
      'collections': '/payments',
      'expenses': '/expenses',
      'banks': '/payouts/accounts',
    };
    final query = MoneyQuery(paths[kind]!, {
      'propertyId': ?['packages', 'banks'].contains(kind) ? null : property,
      'search': search,
      ...filters,
      if (kind == 'collections') 'status': 'CONFIRMED',
    });
    final metrics = <String, String>{
      if (kind == 'dues') ...{
        'allDues': 'All Dues',
        'currentDues': 'Current Dues',
        'monthDues': 'Current Month Dues',
        'unpaidRent': 'Total Unpaid Rent',
      },
      if (kind == 'collections') ...{
        'monthCollection': 'All Collections · Current Month',
        'totalCollection': 'Total Collection',
        'monthDuesCollection': 'Current Month Dues Collection',
        'monthRentCollection': 'Current Month Rent Collection',
        'monthElectricityCollection': 'Current Month Electricity Collection',
        'monthUnattributedCollection': 'Other / Unattributed Collections',
      },
      if (kind == 'expenses') ...{
        'monthExpenses': 'Current Month Total Expenses',
        'activeExpenseCategories': 'Active Expense Categories',
        'salaryExpenses': 'Current Month Salary Expenses',
        'rentExpenses': 'Rent Expenses',
      },
    };
    return Scaffold(
      floatingActionButton: ['packages', 'expenses', 'banks'].contains(kind)
          ? FloatingActionButton(
              tooltip: kind == 'packages'
                  ? 'Add Due Package'
                  : kind == 'expenses'
                  ? 'Add Expense'
                  : 'Add Bank',
              onPressed: () async {
                if (kind == 'banks') {
                  await context.push('/action/bank');
                  if (mounted) refreshMoney(ref);
                } else {
                  await openMoneyScreen(
                    context,
                    MoneyEditor(
                      kind: kind == 'packages' ? 'package' : 'expense',
                    ),
                  );
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: MoneyList(
        query: query,
        header: [
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: kind == 'dues'
                      ? 'Search tenant, phone or room'
                      : 'Search ${kind == 'packages' ? 'due packages' : kind}',
                  trailing: IconButton(
                    tooltip: 'Filter',
                    onPressed: kind == 'banks' ? bankFilter : filter,
                    icon: Badge(
                      isLabelVisible: filters.isNotEmpty,
                      child: const Icon(Icons.tune),
                    ),
                  ),
                  onChanged: (v) {
                    debounce?.cancel();
                    debounce = Timer(const Duration(milliseconds: 350), () {
                      if (mounted) setState(() => search = v.trim());
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              if (kind == 'dues')
                OutlinedButton.icon(
                  onPressed: () =>
                      openMoneyScreen(context, const MoneyBulkReminderScreen()),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text(
                    'Bulk\nReminder',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          if (filters.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                InputChip(
                  label: Text('${filters.length} active filter(s)'),
                  onDeleted: () => setState(() => filters = {}),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (kind == 'collections')
            MoneyReconciliationBanner(property: property),
          if (metrics.isNotEmpty)
            MoneyStats(property: property, labels: metrics),
          const SizedBox(height: 12),
        ],
        item: (row) => switch (kind) {
          'packages' => packageCard(row),
          'dues' => MoneyDueCard(due: row),
          'collections' => collectionCard(row),
          'expenses' => expenseCard(row),
          _ => bankCard(row),
        },
      ),
    );
  }

  Future<void> bankFilter() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in [
            'ALL',
            'ACTIVE',
            'PENDING',
            'SUSPENDED',
            'REJECTED',
          ])
            ListTile(
              title: Text(status),
              onTap: () => Navigator.pop(c, status),
            ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => filters = result == 'ALL' ? {} : {'status': result});
    }
  }

  Widget packageCard(MoneyRow row) => PgCard(
    onTap: () =>
        openMoneyScreen(context, MoneyEditor(kind: 'package', initial: row)),
    child: Row(
      children: [
        const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row['name']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${row['category']} · ${row['propertyType']}'),
              Text(
                '${row['billing']} · ${row['isActive'] == true ? 'Active' : 'Disabled'}',
              ),
            ],
          ),
        ),
        Text(moneyAmount(moneyInt(row['amount']))),
        PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              await openMoneyScreen(
                context,
                MoneyEditor(kind: 'package', initial: row),
              );
              return;
            }
            try {
              await ref.read(apiClientProvider).patch(
                '/money/packages/${row['id']}',
                {...row, 'isActive': row['isActive'] != true},
              );
              if (mounted) refreshMoney(ref);
            } catch (e) {
              if (mounted) {
                showError(context, e);
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit package')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(
                row['isActive'] == true ? 'Disable package' : 'Enable package',
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget collectionCard(MoneyRow row) => MoneyTenantCard(
    resident: moneyMap(row['resident']),
    trailing: Text(
      moneyAmount(moneyInt(row['netAmountPaise'] ?? row['amount'])),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    children: [
      if (moneyInt(row['gatewayRefundedAmount']) > 0)
        Text('Refunded ${moneyAmount(moneyInt(row['gatewayRefundedAmount']))}'),
      const Divider(),
      Row(
        children: [
          Expanded(
            child: Text(
              '${row['mode']} · ${'${row['collectionDate']}'.split('T').first}',
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/action/receipt?id=${row['id']}'),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share Receipt'),
          ),
        ],
      ),
    ],
  );
  Widget expenseCard(MoneyRow row) => PgCard(
    onTap: () =>
        openMoneyScreen(context, MoneyEditor(kind: 'expense', initial: row)),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              child: Icon(moneyExpenseIcon('${row['category']?['name']}')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${row['category']?['name'] ?? 'Expense'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              moneyAmount(moneyInt(row['amount'])),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Paid By: ${row['paidBy'] ?? '—'}\nPaid To: ${row['paidTo'] ?? '—'}\nPayment Mode: ${row['paymentMode']}\n${'${row['expenseDate']}'.split('T').first}',
          ),
        ),
      ],
    ),
  );
  Widget bankCard(MoneyRow row) {
    final isManual = '${row['razorpayAccountId']}'.startsWith('manual_');
    final status = isManual
        ? switch (row['status']) {
            'ACTIVE' => 'Verified for manual payouts',
            'REJECTED' => 'Bank details rejected',
            'SUSPENDED' => 'Bank account suspended',
            _ => 'Awaiting PGInfo review',
          }
        : "${row['status']} · KYC ${row['kycStatus']}";
    return PgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.account_balance_outlined),
            ),
            title: Text('${row['beneficiaryName'] ?? row['businessName']}'),
            subtitle: Text(
              '${row['accountNumberMasked']} · ${row['ifscCode']}\n$status',
            ),
          ),
          if (!isManual)
            const Text(
              'Submit these bank details again to enable manual payouts.',
            ),
          Text(
            'Property: ${row['property']?['name'] ?? 'Organization default'}',
          ),
          TextButton.icon(
            onPressed: () async {
              final picked = await Navigator.push<MoneyRow>(
                context,
                MaterialPageRoute(
                  builder: (_) => const MoneyPropertyScreen(allowUnlink: true),
                ),
              );
              final selected = picked?['id'] as String?;
              if (selected == null) return;
              try {
                await ref.read(apiClientProvider).patch(
                  '/money/banks/${row['id']}/property',
                  {'propertyId': selected.isEmpty ? null : selected},
                );
                if (mounted) refreshMoney(ref);
              } catch (e) {
                if (mounted) {
                  showError(context, e);
                }
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Link a Property'),
          ),
        ],
      ),
    );
  }
}

IconData moneyExpenseIcon(String name) => switch (name.toLowerCase()) {
  'salary' || 'salaries' => Icons.badge_outlined,
  'groceries' => Icons.shopping_basket_outlined,
  'emi' || 'loan emi' => Icons.account_balance_outlined,
  'electrical appliances' => Icons.electrical_services,
  'travel & fuel' => Icons.local_gas_station_outlined,
  'cleaning' => Icons.cleaning_services_outlined,
  'maintenance' => Icons.build_outlined,
  'tax' => Icons.receipt_outlined,
  _ => Icons.receipt_long_outlined,
};

class MoneyReconciliationBanner extends ConsumerWidget {
  const MoneyReconciliationBanner({super.key, this.property});
  final String? property;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref
        .watch(
          moneyObjectProvider(
            MoneyQuery('/money/summary', {'propertyId': ?property}),
          ),
        )
        .asData
        ?.value;
    final count = moneyInt(data?['reconciliationCount']);
    if (count == 0) return const SizedBox.shrink();
    return PgCard(
      onTap: () => openMoneyScreen(
        context,
        MoneyReconciliationScreen(property: property),
      ),
      child: ListTile(
        leading: const Icon(Icons.rule),
        title: Text('$count captured payment(s) need review'),
        subtitle: Text(
          '${moneyAmount(moneyInt(data?['reconciliationAmount']))} · Tap to review balance changes',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class MoneyReconciliationScreen extends StatelessWidget {
  const MoneyReconciliationScreen({super.key, this.property});
  final String? property;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment Review')),
    body: MoneyList(
      query: MoneyQuery('/payments', {
        'status': 'DISPUTED',
        'propertyId': ?property,
      }),
      header: const [
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'These payments were captured after the tenant’s balance changed. Check the gateway transaction and tenant passbook before arranging a refund or adjustment.',
          ),
        ),
      ],
      item: (p) => MoneyTenantCard(
        resident: moneyMap(p['resident']),
        trailing: Text(moneyAmount(moneyInt(p['amount']))),
        children: [
          Text('Gateway reference: ${p['razorpayPaymentId'] ?? '—'}'),
          TextButton(
            onPressed: () => openMoneyScreen(
              context,
              TenantDetailScreen(id: '${p['residentId']}', initialTab: 2),
            ),
            child: const Text('Open Passbook'),
          ),
        ],
      ),
    ),
  );
}

class MoneyDueCard extends StatefulWidget {
  const MoneyDueCard({super.key, required this.due});
  final MoneyRow due;
  @override
  State<MoneyDueCard> createState() => _MoneyDueCardState();
}

class _MoneyDueCardState extends State<MoneyDueCard> {
  bool open = false;
  double drag = 0;
  Future<void> action(String action) async {
    setState(() => open = false);
    final id = '${widget.due['id']}';
    if (action == 'Add Dues') {
      await openMoneyScreen(context, TenantDetailScreen(id: id, initialTab: 2));
    } else {
      await showMoneySheet(context, id, action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.due, r = moneyMap(row['resident']);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Chip(
            avatar: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text('Due on: ${'${row['dueDate']}'.split('T').first}'),
          ),
        ),
        GestureDetector(
          onHorizontalDragStart: (_) => drag = 0,
          onHorizontalDragUpdate: (d) => drag += d.delta.dx,
          onHorizontalDragEnd: (_) {
            if (drag.abs() > 24) setState(() => open = drag < 0);
          },
          child: LayoutBuilder(
            builder: (context, constraints) => ClipRect(
              child: Stack(
                children: [
                  if (open)
                    Positioned(
                      right: 0,
                      top: 4,
                      bottom: 4,
                      width: constraints.maxWidth * .46,
                      child: Material(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final a in [
                              'Give Discount',
                              'Add Dues',
                              'Remind Parent',
                              'Add Remarks',
                            ])
                              TextButton(
                                onPressed: () => action(a),
                                child: Text(a),
                              ),
                          ],
                        ),
                      ),
                    ),
                  AnimatedSlide(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    offset: open ? const Offset(-.46, 0) : Offset.zero,
                    child: AbsorbPointer(
                      absorbing: open,
                      child: MoneyTenantCard(
                        resident: r,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  moneyAmount(moneyInt(row['outstanding'])),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Text(
                                moneyInt(row['overdueDays']) > 0
                                    ? '${row['overdueDays']} days overdue'
                                    : 'Upcoming / due today',
                              ),
                            ],
                          ),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: () => openMoneyScreen(
                                  context,
                                  RecordMoneyPaymentScreen(
                                    residentId: '${row['id']}',
                                  ),
                                ),
                                child: const Text('Record Now'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => showMoneySheet(
                                  context,
                                  '${row['id']}',
                                  'Remind to Pay',
                                ),
                                icon: const Icon(Icons.chat_outlined, size: 18),
                                label: const Text('Remind to Pay'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => open = !open),
            icon: Icon(open ? Icons.close : Icons.more_horiz),
            label: Text(open ? 'Close actions' : 'Quick actions'),
          ),
        ),
      ],
    );
  }
}

class MoneyBulkReminderScreen extends ConsumerStatefulWidget {
  const MoneyBulkReminderScreen({super.key});
  @override
  ConsumerState<MoneyBulkReminderScreen> createState() => _MoneyBulkState();
}

class _MoneyBulkState extends ConsumerState<MoneyBulkReminderScreen> {
  final selected = <String>{};
  String search = '';
  Timer? debounce;
  bool busy = false;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(selectedPropertyProvider);
    ref.listen(selectedPropertyProvider, (_, next) {
      setState(() => selected.clear());
    });
    final query = MoneyQuery('/money/dues', {
      'propertyId': ?property,
      'search': search,
    });
    final page = ref.watch(moneyFeedProvider(query));
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Reminder')),
      body: MoneyList(
        query: query,
        header: [
          SearchField(
            hint: 'Search tenant, phone or room',
            onChanged: (v) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) setState(() => search = v.trim());
              });
            },
          ),
          Row(
            children: [
              TextButton(
                onPressed: page.asData == null
                    ? null
                    : () => setState(
                        () => selected.addAll(
                          page.asData!.value.items
                              .map((r) => '${r['id']}')
                              .take(100 - selected.length),
                        ),
                      ),
                child: const Text('Select loaded'),
              ),
              TextButton(
                onPressed: () => setState(() => selected.clear()),
                child: const Text('Deselect all'),
              ),
            ],
          ),
          Text('${selected.length} selected · Up to 100 per batch'),
          const SizedBox(height: 12),
        ],
        item: (row) => MoneyTenantCard(
          resident: moneyMap(row['resident']),
          trailing: Checkbox(
            value: selected.contains(row['id']),
            onChanged: busy
                ? null
                : (v) => setState(() {
                    if (v == true && selected.length < 100) {
                      selected.add('${row['id']}');
                    } else {
                      selected.remove(row['id']);
                    }
                  }),
          ),
          children: [
            const SizedBox(height: 8),
            Text('Outstanding: ${moneyAmount(moneyInt(row['outstanding']))}'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: busy || selected.isEmpty
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      final result = moneyMap(
                        await ref.read(apiClientProvider).post(
                          '/announcements/reminders/rent',
                          {
                            'residentIds': selected.toList(),
                            'propertyId': ?property,
                            'channel': 'BOTH',
                            'kind': 'rent',
                          },
                        ),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'WhatsApp: ${result['whatsapp']?['accepted'] ?? 0} accepted · Email: ${result['email']?['accepted'] ?? 0} accepted · ${result['failedCount'] ?? 0} failed',
                            ),
                          ),
                        );
                        setState(() => selected.clear());
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showError(context, e);
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(
              busy ? 'Sending…' : 'Send Reminders (${selected.length})',
            ),
          ),
        ),
      ),
    );
  }
}

class MoneyReportsTab extends ConsumerStatefulWidget {
  const MoneyReportsTab({super.key});
  @override
  ConsumerState<MoneyReportsTab> createState() => _MoneyReportsState();
}

class _MoneyReportsState extends ConsumerState<MoneyReportsTab> {
  String search = '';
  Map<String, String> filters = {};
  String? busy;
  @override
  Widget build(BuildContext context) {
    final property = ref.watch(selectedPropertyProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: SearchField(
                hint: 'Search reports',
                onChanged: (v) => setState(() => search = v.toLowerCase()),
              ),
            ),
            IconButton(
              tooltip: 'Report date filters',
              onPressed: () async {
                final result = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MoneyFilterScreen(values: filters),
                  ),
                );
                if (result != null && mounted) setState(() => filters = result);
              },
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        if (filters.isNotEmpty)
          InputChip(
            label: const Text('Date / mode filters applied'),
            onDeleted: () => setState(() => filters = {}),
          ),
        const SizedBox(height: 16),
        for (final type in ['dues', 'collections', 'expenses'])
          if (type.contains(search))
            PgCard(
              child: ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: Text(
                  '${type[0].toUpperCase()}${type.substring(1)} Report',
                ),
                subtitle: const Text('Generate and download CSV'),
                trailing: busy == type
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.download_outlined),
                onTap: busy != null
                    ? null
                    : () async {
                        setState(() => busy = type);
                        try {
                          final csv = await ref
                              .read(apiClientProvider)
                              .get(
                                '/money/reports/$type',
                                query: {'propertyId': ?property, ...filters},
                              );
                          final directory = await getTemporaryDirectory();
                          final file = File(
                            '${directory.path}/$type-${DateTime.now().millisecondsSinceEpoch}.csv',
                          );
                          await file.writeAsString(csv.toString(), flush: true);
                          if (!context.mounted) return;
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path, mimeType: 'text/csv')],
                              subject: 'PgInfo $type report',
                              sharePositionOrigin: moneyShareOrigin(context),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        } finally {
                          if (mounted) setState(() => busy = null);
                        }
                      },
              ),
            ),
      ],
    );
  }
}
