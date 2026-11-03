import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Dues'),
            Tab(text: 'Collections'),
            Tab(text: 'Expense'),
            Tab(text: 'Reports'),
            Tab(text: 'Bank'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _DuesTab(),
          _CollectionsTab(),
          _ExpenseTab(),
          _ReportsTab(),
          _BankTab(),
        ],
      ),
    ),
  );
}

class _DuesTab extends ConsumerStatefulWidget {
  const _DuesTab();
  @override
  ConsumerState<_DuesTab> createState() => _DuesState();
}

class _DuesState extends ConsumerState<_DuesTab> {
  String search = '';
  String status = 'All';
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(selectedPropertyProvider);
    final query = PagedQuery(
      path: '/billing/records',
      propertyId: property,
      search: search,
      status: status == 'All' ? null : status,
    );
    final records = ref.watch(pagedListProvider(query));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: SearchField(
                hint: 'Search tenant',
                onChanged: (v) {
                  debounce?.cancel();
                  debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => mounted ? setState(() => search = v) : null,
                  );
                },
              ),
            ),
            IconButton(
              tooltip: 'Bulk reminder',
              onPressed: () => context.push('/action/reminders'),
              icon: const Icon(Icons.notifications_active_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'View analytics dashboard',
                value: 'Insights',
                onTap: () => context.push('/analytics'),
              ),
            ),
            Expanded(
              child: PgAsync(
                value: ref.watch(dashboardProvider),
                data: (data) {
                  final financial = data['financial'] as Map;
                  return MetricCard(
                    label: 'All dues',
                    value: rupees(financial['outstandingBalancePaise'] as num),
                    icon: Icons.payments_outlined,
                  );
                },
              ),
            ),
          ],
        ),
        PgAsync(
          value: ref.watch(dashboardProvider),
          data: (data) {
            final financial = data['financial'] as Map;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.55,
              children: [
                MetricCard(
                  label: 'Current dues',
                  value: rupees(financial['currentDuesPaise'] as num),
                ),
                MetricCard(
                  label: 'This month',
                  value: rupees(financial['monthOutstandingPaise'] as num),
                ),
                MetricCard(
                  label: 'Future dues',
                  value: rupees(financial['futureDuesPaise'] as num),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['All', 'ISSUED', 'PARTIALLY_PAID', 'OVERDUE', 'PAID']
              .map(
                (s) => ChoiceChip(
                  label: Text(s.replaceAll('_', ' ')),
                  selected: status == s,
                  onSelected: (_) => setState(() => status = s),
                ),
              )
              .toList(),
        ),
        PgAsync(
          value: records,
          retry: () => ref.invalidate(pagedListProvider(query)),
          data: (items) => Column(
            children: [
              for (final due in items)
                PgCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(due['resident'] as Map?)?['firstName'] ?? 'Tenant'} ${(due['resident'] as Map?)?['lastName'] ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Room ${((due['resident'] as Map?)?['room'] as Map?)?['roomNumber'] ?? '—'} • ${due['status']}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rupees(
                          (due['amount'] as num) - (due['paidAmount'] as num),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => context.push(
                              '/action/record?residentId=${due['residentId']}&billingRecordId=${due['id']}',
                            ),
                            child: const Text('Record now'),
                          ),
                          TextButton(
                            onPressed: () => context.push(
                              '/action/message?residentId=${due['residentId']}',
                            ),
                            child: const Text('Remind to pay'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (ref.read(pagedListProvider(query).notifier).hasMore)
                TextButton(
                  onPressed: () =>
                      ref.read(pagedListProvider(query).notifier).loadMore(),
                  child: const Text('Load more dues'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionsTab extends ConsumerStatefulWidget {
  const _CollectionsTab();
  @override
  ConsumerState<_CollectionsTab> createState() => _CollectionsState();
}

class _CollectionsState extends ConsumerState<_CollectionsTab> {
  String search = '';
  String mode = 'All';
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(selectedPropertyProvider);
    final query = PagedQuery(
      path: '/payments',
      propertyId: property,
      search: search,
      filterName: mode == 'All' ? null : 'mode',
      filterValue: mode == 'All' ? null : mode,
    );
    final payments = ref.watch(pagedListProvider(query));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SearchField(
          hint: 'Search collections',
          onChanged: (value) {
            debounce?.cancel();
            debounce = Timer(
              const Duration(milliseconds: 350),
              () => mounted ? setState(() => search = value) : null,
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['All', 'CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE']
              .map(
                (value) => ChoiceChip(
                  label: Text(value.replaceAll('_', ' ')),
                  selected: mode == value,
                  onSelected: (_) => setState(() => mode = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        MetricCard(
          label: 'View analytics dashboard',
          value: 'Insights',
          onTap: () => context.push('/analytics'),
        ),
        PgAsync(
          value: ref.watch(dashboardProvider),
          data: (data) {
            final financial = data['financial'] as Map;
            return Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Total collection',
                    value: rupees(financial['totalCollectedPaise'] as num),
                  ),
                ),
                Expanded(
                  child: MetricCard(
                    label: 'Current month',
                    value: rupees(financial['monthCollectedPaise'] as num),
                  ),
                ),
              ],
            );
          },
        ),
        PgAsync(
          value: payments,
          retry: () => ref.invalidate(pagedListProvider(query)),
          data: (items) => Column(
            children: [
              MetricCard(
                label: 'Collections loaded',
                value: '${items.length}',
                icon: Icons.receipt_long,
              ),
              for (final payment in items)
                PgCard(
                  child: ListTile(
                    title: Text(rupees(payment['amount'] as num)),
                    subtitle: Text('${payment['mode']} • ${payment['status']}'),
                    trailing: IconButton(
                      onPressed: () =>
                          context.push('/action/receipt?id=${payment['id']}'),
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ),
                ),
              if (ref.read(pagedListProvider(query).notifier).hasMore)
                TextButton(
                  onPressed: () =>
                      ref.read(pagedListProvider(query).notifier).loadMore(),
                  child: const Text('Load more collections'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseTab extends ConsumerStatefulWidget {
  const _ExpenseTab();
  @override
  ConsumerState<_ExpenseTab> createState() => _ExpenseState();
}

class _ExpenseState extends ConsumerState<_ExpenseTab> {
  String search = '';
  String mode = 'All';
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(selectedPropertyProvider);
    final query = PagedQuery(
      path: '/expenses',
      propertyId: property,
      search: search,
      filterName: mode == 'All' ? null : 'paymentMode',
      filterValue: mode == 'All' ? null : mode,
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/action/expense'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchField(
            hint: 'Search expenses',
            onChanged: (value) {
              debounce?.cancel();
              debounce = Timer(
                const Duration(milliseconds: 350),
                () => mounted ? setState(() => search = value) : null,
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['All', 'CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value.replaceAll('_', ' ')),
                    selected: mode == value,
                    onSelected: (_) => setState(() => mode = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          PgAsync(
            value: ref.watch(dashboardProvider),
            data: (data) {
              final financial = data['financial'] as Map;
              return Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Total expenses',
                      value: rupees(financial['totalExpensesPaise'] as num),
                    ),
                  ),
                  Expanded(
                    child: MetricCard(
                      label: 'Current month',
                      value: rupees(financial['monthExpensesPaise'] as num),
                    ),
                  ),
                ],
              );
            },
          ),
          PgAsync(
            value: ref.watch(pagedListProvider(query)),
            retry: () => ref.invalidate(pagedListProvider(query)),
            data: (items) => Column(
              children: [
                MetricCard(
                  label: 'Loaded expenses',
                  value: rupees(
                    items.fold<int>(
                      0,
                      (sum, e) => sum + (e['amount'] as num).toInt(),
                    ),
                  ),
                  icon: Icons.money_off,
                ),
                for (final expense in items)
                  PgCard(
                    onTap: () =>
                        context.push('/action/expense?id=${expense['id']}'),
                    child: ListTile(
                      title: Text(
                        '${expense['category']?['name'] ?? 'Expense'} • ${rupees(expense['amount'] as num)}',
                      ),
                      subtitle: Text(
                        'Paid by ${expense['paidBy'] ?? '—'} • To ${expense['paidTo'] ?? '—'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                if (ref.read(pagedListProvider(query).notifier).hasMore)
                  TextButton(
                    onPressed: () =>
                        ref.read(pagedListProvider(query).notifier).loadMore(),
                    child: const Text('Load more expenses'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (final report in ['collections', 'residents', 'expenses'])
        PgCard(
          onTap: () => context.push('/action/report?type=$report'),
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(
              '${report[0].toUpperCase()}${report.substring(1)} report',
            ),
            subtitle: const Text('Export CSV'),
            trailing: const Icon(Icons.download_outlined),
          ),
        ),
    ],
  );
}

class _BankTab extends ConsumerWidget {
  const _BankTab();
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: ref.read(repositoryProvider).list('/payouts/accounts'),
    builder: (context, snapshot) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SearchField(hint: 'Search bank accounts'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/action/bank'),
          icon: const Icon(Icons.add),
          label: const Text('Add bank'),
        ),
        if (snapshot.hasError) Text(snapshot.error.toString()),
        if (!snapshot.hasData && !snapshot.hasError)
          const Center(child: CircularProgressIndicator()),
        if (snapshot.hasData)
          for (final account in snapshot.data!)
            PgCard(
              child: ListTile(
                title: Text(
                  '${account['ownerName'] ?? account['businessName'] ?? 'Account'}',
                ),
                subtitle: Text(
                  '${account['status'] ?? ''} • ${account['kycStatus'] ?? ''}',
                ),
              ),
            ),
      ],
    ),
  );
}
