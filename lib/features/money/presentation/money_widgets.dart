import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/components/common.dart';
import '../money_data.dart';

class MoneySkeleton extends StatefulWidget {
  const MoneySkeleton({super.key, this.form = false, this.compact = false});
  final bool form, compact;
  @override
  State<MoneySkeleton> createState() => _MoneySkeletonState();
}

class _MoneySkeletonState extends State<MoneySkeleton>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else {
      animation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading money details',
    liveRegion: true,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Opacity(
          opacity: MediaQuery.disableAnimationsOf(context)
              ? 1
              : .55 + animation.value * .4,
          child: Column(
            children: [
              for (var i = 0; i < (widget.compact ? 1 : 3); i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: block(context, 18)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        block(context, 14),
                        const SizedBox(height: 12),
                        FractionallySizedBox(
                          widthFactor: .65,
                          child: block(context, widget.form ? 48 : 14),
                        ),
                        const SizedBox(height: 12),
                        block(context, widget.form ? 48 : 30),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget block(BuildContext c, double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(c).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class MoneyAsync<T> extends StatelessWidget {
  const MoneyAsync({
    super.key,
    required this.value,
    required this.builder,
    this.retry,
    this.form = false,
    this.compact = false,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback? retry;
  final bool form, compact;
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: true,
    loading: () => form
        ? const SingleChildScrollView(child: MoneySkeleton(form: true))
        : MoneySkeleton(compact: compact),
    error: (error, _) => PgCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined),
          const SizedBox(height: 8),
          Text(error.toString(), textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
    data: builder,
  );
}

class MoneyStats extends ConsumerWidget {
  const MoneyStats({super.key, required this.property, required this.labels});
  final String? property;
  final Map<String, String> labels;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = MoneyQuery('/money/summary', {'propertyId': ?property});
    return MoneyAsync(
      value: ref.watch(moneyObjectProvider(query)),
      compact: true,
      retry: () => ref.invalidate(moneyObjectProvider(query)),
      builder: (data) => SizedBox(
        height: 136,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final entry in labels.entries)
              SizedBox(
                width: 178,
                child: MetricCard(
                  label: entry.value,
                  value: entry.key == 'activeExpenseCategories'
                      ? '${data[entry.key] ?? 0}'
                      : moneyAmount(moneyInt(data[entry.key])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MoneyList extends ConsumerWidget {
  const MoneyList({
    super.key,
    required this.query,
    required this.header,
    required this.item,
    this.empty = 'No results found',
  });
  final MoneyQuery query;
  final List<Widget> header;
  final Widget Function(MoneyRow) item;
  final String empty;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moneyFeedProvider(query));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(moneyObjectProvider);
        ref.invalidate(moneyFeedProvider(query));
        await ref.read(moneyFeedProvider(query).future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList.list(children: header),
          ),
          ...state.when<List<Widget>>(
            skipLoadingOnRefresh: true,
            loading: () => [
              const SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(child: MoneySkeleton()),
              ),
            ],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: MoneyAsync(
                  value: state,
                  builder: (_) => const SizedBox.shrink(),
                  retry: () => ref.invalidate(moneyFeedProvider(query)),
                ),
              ),
            ],
            data: (page) => [
              if (page.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(empty)),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: page.items.length,
                  itemBuilder: (context, index) => item(page.items[index]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: Column(
                    children: [
                      Text('Showing ${page.items.length} of ${page.total}'),
                      if (page.appendError != null)
                        Text(
                          '${page.appendError}',
                          textAlign: TextAlign.center,
                        ),
                      if (page.hasMore)
                        page.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: () => ref
                                    .read(moneyFeedProvider(query).notifier)
                                    .loadMore(),
                                child: Text(
                                  page.appendError != null
                                      ? 'Retry loading more'
                                      : 'Load more',
                                ),
                              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MoneyTenantCard extends StatelessWidget {
  const MoneyTenantCard({
    super.key,
    required this.resident,
    this.trailing,
    this.children = const [],
  });
  final MoneyRow resident;
  final Widget? trailing;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => PgCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              child: Text(
                (resident['firstName'] as String? ?? 'T')
                        .characters
                        .firstOrNull ??
                    'T',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moneyName(resident),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(moneyRoom(resident)),
                  if (resident['mobile'] != null)
                    Text(
                      '${resident['mobile']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        ...children,
      ],
    ),
  );
}

class MoneyFilterScreen extends StatefulWidget {
  const MoneyFilterScreen({
    super.key,
    required this.values,
    this.dues = false,
    this.packages = false,
    this.expense = false,
  });
  final Map<String, String> values;
  final bool dues, packages, expense;
  @override
  State<MoneyFilterScreen> createState() => _MoneyFilterState();
}

class _MoneyFilterState extends State<MoneyFilterScreen> {
  Map<String, String> get defaults => widget.dues
      ? {'sort': 'DATE_ASC', 'date': 'ALL', 'defaulter': 'ALL', 'type': ''}
      : widget.packages
      ? {'active': 'ACTIVE'}
      : {widget.expense ? 'paymentMode' : 'mode': ''};
  late Map<String, String> values = {...defaults, ...widget.values};
  Widget section(String title, String key, Map<String, String> options) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: values[key] == e.key,
                  onSelected: (_) => setState(() => values[key] = e.key),
                ),
            ],
          ),
        ],
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Filter'),
      actions: [
        TextButton(
          onPressed: () => setState(() => values = {...defaults}),
          child: const Text('Reset'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.dues) ...[
          section('Sort By', 'sort', {
            'DATE_ASC': 'Due Date – Oldest to Newest',
            'DATE_DESC': 'Due Date – Newest to Oldest',
            'ROOM': 'Room Number',
            'AMOUNT_DESC': 'Due Amount – High to Low',
            'AMOUNT_ASC': 'Due Amount – Low to High',
          }),
          section('Due Date', 'date', {
            'ALL': 'All Time',
            'TODAY': 'Today',
            'YESTERDAY': 'Yesterday',
            '30_DAYS': 'Last 30 Days',
            '3_MONTHS': 'Last 3 Months',
            '6_MONTHS': 'Last 6 Months',
          }),
          section('Defaulter', 'defaulter', {
            'ALL': 'All Dues',
            'RENT': 'Rent',
            'OTHER': 'Other Bills',
          }),
          section('Due Types', 'type', {
            '': 'All',
            'RENT': 'Rent',
            'SECURITY_DEPOSIT': 'Security Deposit',
            'ELECTRICITY': 'Electricity',
            'WIFI': 'Wi-Fi',
            'MAINTENANCE': 'Maintenance Bill',
            'OTHER': 'Other',
          }),
        ] else if (widget.packages)
          section('Status', 'active', {
            'ALL': 'All',
            'ACTIVE': 'Active',
            'DISABLED': 'Disabled',
          })
        else ...[
          section('Payment mode', widget.expense ? 'paymentMode' : 'mode', {
            '': 'All',
            for (final mode in paymentModes) mode: mode.replaceAll('_', ' '),
          }),
          for (final key in ['startDate', 'endDate'])
            ListTile(
              title: Text(key == 'startDate' ? 'From date' : 'To date'),
              subtitle: Text(values[key] ?? 'All time'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(values[key] ?? '') ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(
                    () => values[key] = date.toIso8601String().substring(0, 10),
                  );
                }
              },
            ),
        ],
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () {
            if (values['startDate'] != null &&
                values['endDate'] != null &&
                values['startDate']!.compareTo(values['endDate']!) > 0) {
              showError(context, 'From date must be before To date');
              return;
            }
            Navigator.pop(
              context,
              Map<String, String>.fromEntries(
                values.entries.where((e) => e.value.isNotEmpty),
              ),
            );
          },
          child: const Text('Apply filters'),
        ),
      ),
    ),
  );
}

Future<void> openMoneyScreen(BuildContext context, Widget screen) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen));
