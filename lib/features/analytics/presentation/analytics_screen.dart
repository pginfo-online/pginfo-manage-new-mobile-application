import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/di/providers.dart';
import '../../../core/design_system/theme.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

const _green = PgTheme.positive, _red = PgTheme.negative;
Map<String, dynamic> _part(Map<String, dynamic> data, String key) =>
    Map<String, dynamic>.from(data[key] as Map? ?? {});
int _n(Map<String, dynamic> data, String key) =>
    (data[key] as num?)?.round() ?? 0;
String _r(Map<String, dynamic> data, String key) => rupees(_n(data, key));

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime period = DateTime(DateTime.now().year, DateTime.now().month);
  bool fy = false, combined = false, showPeriods = false, nowSelected = false;
  String search = '', financeView = 'Dues', breakup = 'Category';
  int propertyPages = 1;
  Timer? searchTimer;

  @override
  void dispose() {
    searchTimer?.cancel();
    super.dispose();
  }

  String get periodLabel {
    if (fy) return 'Current FY';
    final now = DateTime.now(),
        last = DateTime(DateTime.now().year, DateTime.now().month - 1);
    if (period.year == now.year && period.month == now.month) {
      return 'This Month';
    }
    if (period.year == last.year && period.month == last.month) {
      return 'Last Month';
    }
    return DateFormat.yMMM().format(period);
  }

  Future<void> choosePeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: period,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (mounted && picked != null) {
      setState(() {
        period = DateTime(picked.year, picked.month);
        fy = false;
        nowSelected = false;
        showPeriods = false;
      });
    }
  }

  void setPeriod(String label) {
    if (label == 'Custom') {
      choosePeriod();
      return;
    }
    final now = DateTime.now();
    setState(() {
      period = label == 'Last Month'
          ? DateTime(now.year, now.month - 1)
          : DateTime(now.year, now.month);
      fy = label == 'Current FY';
      nowSelected = label == 'Now';
      showPeriods = false;
    });
  }

  ColorScheme get colors => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPropertyProvider);
    final name = selected == null
        ? 'All properties'
        : ref.watch(dashboardPropertyNameProvider(selected)).asData?.value ??
              'Property';
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? PgTheme.darkCanvas
            : PgTheme.analyticsCanvas,
        appBar: AppBar(
          title: InkWell(
            onTap: () => context.push('/properties/select'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xffb9c5fa),
            tabs: [
              Tab(text: "Bird's Eye View"),
              Tab(text: 'Financials'),
              Tab(text: 'Occupancy'),
              Tab(text: 'Tenants'),
              Tab(text: 'Issues'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Consumer(builder: (context, ref, _) => _birds(ref, selected)),
            for (final buildTab in [_financial, _occupancy, _tenants, _issues])
              Consumer(
                builder: (context, ref, _) {
                  final provider = dashboardPeriodProvider((
                    propertyId: selected,
                    month: period.month,
                    year: period.year,
                    fy: fy,
                  ));
                  final value = ref.watch(provider);
                  return _async(
                    value,
                    buildTab,
                    () => ref.invalidate(provider),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _async(
    AsyncValue<Map<String, dynamic>> value,
    Widget Function(Map<String, dynamic>) builder,
    VoidCallback retry,
  ) {
    final data = value.asData?.value;
    if (data != null) return builder(data);
    if (value.hasError) {
      return PgAsync(value: value, data: builder, retry: retry);
    }
    return const _DashboardSkeleton();
  }

  Widget _birds(WidgetRef ref, String? selected) {
    final matches = <Property>[];
    var hasMore = false;
    var loading = false;
    Object? error;
    var missingPage = 1;
    for (var page = 1; page <= propertyPages; page++) {
      final value = ref.watch(
        dashboardPropertiesProvider((search: search, page: page)),
      );
      final result = value.asData?.value;
      if (result == null) {
        missingPage = page;
        loading = value.isLoading;
        error = value.error;
        break;
      }
      matches.addAll(result.items);
      hasMore = result.hasMore;
    }
    return Column(
      children: [
        Container(
          color: colors.surface,
          padding: const EdgeInsets.all(16),
          child: SearchField(
            hint: 'Search properties',
            onChanged: (v) {
              searchTimer?.cancel();
              searchTimer = Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() {
                    search = v.trim();
                    propertyPages = 1;
                  });
                }
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount:
                1 +
                (combined ? 1 : 0) +
                (matches.isEmpty && !combined ? 1 : 0) +
                matches.length +
                ((matches.isNotEmpty || combined) &&
                        (hasMore || loading || error != null)
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _panel(
                  Row(
                    children: [
                      const Icon(Icons.show_chart, color: PgTheme.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Show combined summary',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: combined,
                        onChanged: (v) => setState(() => combined = v),
                      ),
                    ],
                  ),
                );
              }
              if (combined && index == 1) {
                return _property('Combined summary', null, selected == null);
              }
              if (matches.isEmpty && index == 1) {
                if (loading) return _panel(const _SkeletonLines());
                if (error != null) {
                  return _panel(
                    TextButton(
                      onPressed: () => ref.invalidate(
                        dashboardPropertiesProvider((
                          search: search,
                          page: missingPage,
                        )),
                      ),
                      child: const Text('Retry loading properties'),
                    ),
                  );
                }
                return _panel(const Text('No properties match your search.'));
              }
              final propertyIndex = index - 1 - (combined ? 1 : 0);
              if (propertyIndex >= matches.length) {
                if (loading) return _panel(const _SkeletonLines());
                if (error != null) {
                  return _panel(
                    TextButton(
                      onPressed: () => ref.invalidate(
                        dashboardPropertiesProvider((
                          search: search,
                          page: missingPage,
                        )),
                      ),
                      child: const Text('Retry loading properties'),
                    ),
                  );
                }
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() => propertyPages++),
                    child: const Text('Load more properties'),
                  ),
                );
              }
              final p = matches[propertyIndex];
              return _property(p.name, p.id, p.id == selected);
            },
          ),
        ),
      ],
    );
  }

  Widget _property(String name, String? id, bool current) => Consumer(
    builder: (context, ref, _) {
      final provider = dashboardPeriodProvider((
        propertyId: id,
        month: period.month,
        year: period.year,
        fy: fy,
      ));
      final value = ref.watch(provider);
      final data = value.asData?.value;
      if (data == null) {
        return _panel(
          value.hasError
              ? ListTile(
                  title: Text(name),
                  subtitle: TextButton(
                    onPressed: () => ref.invalidate(provider),
                    child: const Text('Retry loading summary'),
                  ),
                )
              : const _SkeletonLines(),
        );
      }
      final op = _part(data, 'operational'), f = _part(data, 'financial');
      final beds = _n(op, 'totalBeds'),
          occupied = _n(op, 'occupiedBeds'),
          window = fy ? 'Current FY' : DateFormat.MMMM().format(period);
      return _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (current) const Chip(label: Text('Current')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Occupied Beds')),
                      Text(
                        '$occupied/$beds',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: beds == 0 ? 0 : (occupied / beds).clamp(0.0, 1.0),
                    color: _green,
                    backgroundColor: colors.surfaceContainerHighest,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _line("Today's Collection", _r(f, 'todayCollectedPaise'), _green),
            _line('$window Collections', _r(f, 'monthCollectedPaise'), _green),
            _line('$window Dues', _r(f, 'monthOutstandingPaise'), _red),
            _line('Total Dues', _r(f, 'outstandingBalancePaise'), _red),
            _line('$window Expenses', _r(f, 'monthExpensesPaise'), _red),
            _line(
              'Rent Defaulters',
              '${_n(op, 'rentDefaulters')}',
              Colors.purple,
            ),
            _line(
              'Available Deposits',
              _r(f, 'securityDepositsHeldPaise'),
              _green,
            ),
            _line(
              'Pending Deposits',
              _r(f, 'pendingDepositsPaise'),
              Colors.orange,
            ),
            _line('$window Profit', _r(f, 'monthProfitPaise'), _green),
            _line('Potential Rent', _r(f, 'potentialRentPaise'), PgTheme.blue),
            _line('Active Tenants', '${_n(op, 'activeTenants')}', PgTheme.blue),
            _line(
              'Notice Period Tenants',
              '${_n(op, 'noticePeriodTenants')}',
              _red,
            ),
            _line(
              'Current Bookings',
              '${_n(op, 'currentBookings')}',
              PgTheme.blue,
            ),
            _line('Total Rooms', '${_n(op, 'totalRooms')}', PgTheme.blue),
            _line('Active Leads', '${_n(op, 'activeLeads')}', PgTheme.blue),
            _line('Active Complaints', '${_n(op, 'pendingComplaints')}', _red),
          ],
        ),
      );
    },
  );
  Widget _financial(Map<String, dynamic> data) {
    final f = _part(data, 'financial');
    return _scroll([
      _chips(
        ['$periodLabel ⌄', 'Dues', 'Collections'],
        [
          () => setState(() => showPeriods = !showPeriods),
          () => setState(() => financeView = 'Dues'),
          () => setState(() => financeView = 'Collections'),
        ],
        financeView,
      ),
      if (showPeriods) _periodFilters(false),
      if (financeView == 'Dues') ...[
        _snapshot(
          'Dues Overview',
          [
            (_r(f, 'outstandingBalancePaise'), 'All-time dues'),
            (_r(f, 'pastDuesPaise'), 'Before selected period'),
            (_r(f, 'monthOutstandingPaise'), 'Period dues'),
          ],
          [
            ('All-time dues', _r(f, 'outstandingBalancePaise')),
            ('Before selected period', _r(f, 'pastDuesPaise')),
            ('Period dues', _r(f, 'monthOutstandingPaise')),
            ('Overdue', _r(f, 'overdueDuesPaise')),
          ],
        ),
        _chart('Live Dues', [
          ('Total dues', _n(f, 'outstandingBalancePaise'), PgTheme.blue),
          ('Overdue', _n(f, 'overdueDuesPaise'), _red),
          ('Due today', _n(f, 'todayDuesPaise'), Colors.orange),
          ('Due this week', _n(f, 'weekDuesPaise'), _green),
          ('Due later', _n(f, 'futureDuesPaise'), Colors.purple),
        ], money: true),
        _panel(
          Column(
            children: [
              const _Title('Bills Summary'),
              _line('Bills due', _r(f, 'monthOutstandingPaise'), _red),
              _line('Bills received', _r(f, 'monthCollectedPaise'), _green),
            ],
          ),
        ),
      ] else ...[
        _snapshot(
          'Collection Overview',
          [
            (_r(f, 'totalCollectedPaise'), 'Total Collection'),
            (_r(f, 'monthCollectedPaise'), 'Period collections'),
          ],
          [
            ('Total collections', _r(f, 'totalCollectedPaise')),
            ('Period collections', _r(f, 'monthCollectedPaise')),
            ("Today's collections", _r(f, 'todayCollectedPaise')),
          ],
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Title('Collection Breakup'),
              _chips(
                ['Category', 'Status', 'Mode', 'Received By'],
                [
                  for (final item in [
                    'Category',
                    'Status',
                    'Mode',
                    'Received By',
                  ])
                    () => setState(() => breakup = item),
                ],
                breakup,
              ),
              const SizedBox(height: 12),
              Text('Total Collection ${_r(f, 'monthCollectedPaise')}'),
              ..._breakdown(f),
            ],
          ),
        ),
        _chart('Collection Status', [
          ('Period dues', _n(f, 'monthOutstandingPaise'), PgTheme.blue),
          ('Past dues', _n(f, 'pastDuesPaise'), const Color(0xffdbe8f7)),
        ], money: true),
      ],
    ]);
  }

  Widget _occupancy(Map<String, dynamic> data) {
    final op = _part(data, 'operational'), f = _part(data, 'financial');
    final total = _n(op, 'totalBeds'), occupied = _n(op, 'occupiedBeds');
    return _scroll([
      _periodFilters(true),
      _snapshot(
        'Overview Snapshot',
        [
          ('$total', 'Rentable Beds'),
          ('$occupied', 'Occupied Beds'),
          ('${_n(op, 'availableBeds')}', 'Vacant Beds'),
        ],
        [
          ('Rentable beds', '$total'),
          ('Occupied beds', '$occupied'),
          ('Vacant beds', '${_n(op, 'availableBeds')}'),
          ('Occupancy rate', '${_n(op, 'occupancyRate')}%'),
        ],
      ),
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Title('Occupancy Status'),
            Text(
              'Total rentable beds: $total',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Flexible(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 14,
                            color: _red,
                          ),
                        ),
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: total == 0
                                ? 0
                                : (occupied / total).clamp(0.0, 1.0),
                            strokeWidth: 14,
                            color: _green,
                          ),
                        ),
                        Text(
                          '${_n(op, 'occupancyRate')}%',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _line('Occupied', '$occupied', _green),
                      if (_n(op, 'reservedBeds') > 0)
                        _line(
                          'Reserved',
                          '${_n(op, 'reservedBeds')}',
                          Colors.orange,
                        ),
                      _line(
                        'Available',
                        '${_n(op, 'availableBeds')}',
                        PgTheme.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _panel(
        Column(
          children: [
            const _Title('Revenue per bed'),
            _line(
              'Average rent per bed',
              total == 0 ? '₹0' : rupees(_n(f, 'potentialRentPaise') / total),
              PgTheme.blue,
            ),
            _line(
              'Average revenue per bed',
              total == 0 ? '₹0' : rupees(_n(f, 'monthCollectedPaise') / total),
              _green,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _tenants(Map<String, dynamic> data) {
    final op = _part(data, 'operational');
    return _scroll([
      _periodFilters(false),
      _snapshot(
        'Overview Snapshot',
        [
          ('${_n(op, 'activeTenants')}', 'Active Tenants'),
          ('${_n(op, 'currentBookings')}', 'Active Bookings'),
          ('${_n(op, 'approvedBookings')}', 'Approved Bookings'),
          ('${_n(op, 'noticePeriodTenants')}', 'Notice Raised'),
        ],
        [
          ('Active tenants', '${_n(op, 'activeTenants')}'),
          ('Active bookings', '${_n(op, 'currentBookings')}'),
          ('Approved bookings', '${_n(op, 'approvedBookings')}'),
          ('Notice raised', '${_n(op, 'noticePeriodTenants')}'),
        ],
      ),
      _chart('Tenant Journey', [
        ('Move-ins', _n(op, 'periodMoveIns'), _green),
        ('Move-outs', _n(op, 'periodMoveOuts'), _red),
        ('Upcoming move-ins', _n(op, 'upcomingMoveIns'), PgTheme.blue),
      ]),
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Title('Tenant Verification'),
            _line(
              'ID proof uploaded',
              '${_n(op, 'residentsWithIdProof')}',
              _green,
            ),
            _line(
              'ID proof pending',
              '${(_n(op, 'activeTenants') - _n(op, 'residentsWithIdProof')).clamp(0, 999999999)}',
              _red,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _issues(Map<String, dynamic> data) {
    final op = _part(data, 'operational');
    return _scroll([
      _periodFilters(false),
      _snapshot(
        'Overview Snapshot',
        [
          ('${_n(op, 'periodComplaintsCreated')}', 'Issues Created'),
          ('${_n(op, 'periodComplaintsResolved')}', 'Issues Resolved'),
        ],
        [
          ('Issues created', '${_n(op, 'periodComplaintsCreated')}'),
          ('Issues resolved', '${_n(op, 'periodComplaintsResolved')}'),
          ('Currently open', '${_n(op, 'pendingComplaints')}'),
        ],
      ),
      _chart('Current Status', [
        ('Open', _n(op, 'pendingComplaints'), _red),
        ('Resolved', _n(op, 'periodComplaintsResolved'), _green),
      ]),
      _chart('Ageing Distribution', [
        (
          'Under 7 days',
          _n(_part(op, 'complaintAgeing'), 'under7Days'),
          _green,
        ),
        (
          '7–30 days',
          _n(_part(op, 'complaintAgeing'), 'days7To30'),
          Colors.orange,
        ),
        ('Over 30 days', _n(_part(op, 'complaintAgeing'), 'over30Days'), _red),
      ]),
    ]);
  }

  Widget _periodFilters(bool now) => _chips(
    [if (now) 'Now', 'This Month', 'Last Month', 'Current FY', 'Custom'],
    [
      if (now) () => setPeriod('Now'),
      () => setPeriod('This Month'),
      () => setPeriod('Last Month'),
      () => setPeriod('Current FY'),
      choosePeriod,
    ],
    now && nowSelected
        ? 'Now'
        : const ['This Month', 'Last Month', 'Current FY'].contains(periodLabel)
        ? periodLabel
        : 'Custom',
  );
  Widget _scroll(List<Widget> children) => RefreshIndicator(
    onRefresh: () async {
      final provider = dashboardPeriodProvider((
        propertyId: ref.read(selectedPropertyProvider),
        month: period.month,
        year: period.year,
        fy: fy,
      ));
      try {
        ref.invalidate(provider);
        await ref.read(provider.future);
      } catch (_) {
        // The mounted analytics tab displays the provider error and retry.
      }
    },
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children,
    ),
  );
  Widget _panel(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
  Widget _chips(
    List<String> labels,
    List<VoidCallback> actions,
    String selected,
  ) => SizedBox(
    height: 56,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: labels.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final active = labels[i] == selected;
        return ActionChip(
          label: Text(labels[i]),
          onPressed: actions[i],
          backgroundColor: active ? colors.primaryContainer : colors.surface,
          labelStyle: TextStyle(
            color: active ? colors.onPrimaryContainer : colors.onSurface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(
              color: active ? colors.primary : colors.outlineVariant,
            ),
          ),
        );
      },
    ),
  );
  Widget _snapshot(
    String title,
    List<(String, String)> cards,
    List<(String, String)> detail,
  ) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Title(title)),
            TextButton(
              onPressed: () => _showDetail(title, detail),
              child: const Text('View all ›'),
            ),
          ],
        ),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(124) + 24,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => Container(
              width: 145,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cards[i].$1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: Text(
                      cards[i].$2,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  void _showDetail(String title, List<(String, String)> rows) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheet),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                for (final row in rows) _line(row.$1, row.$2, PgTheme.blue),
              ],
            ),
          ),
        ),
      );
  Widget _chart(
    String title,
    List<(String, int, Color)> rows, {
    bool money = false,
  }) {
    final max = rows.fold<int>(1, (a, b) => b.$2 > a ? b.$2 : a);
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title(title),
          for (final row in rows)
            _bar(row.$1, row.$2, max, row.$3, money: money),
        ],
      ),
    );
  }

  List<Widget> _breakdown(Map<String, dynamic> financial) {
    final raw = financial['collectionBreakdown'] as List? ?? [];
    final rows = raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((item) => item['dimension'] == breakup)
        .toList();
    if (rows.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text('No collections in this period.'),
        ),
      ];
    }
    final max = rows.fold<int>(
      1,
      (current, item) =>
          _n(item, 'amountPaise') > current ? _n(item, 'amountPaise') : current,
    );
    return [
      for (final row in rows)
        _bar(
          (row['label'] as String).replaceAll('_', ' '),
          _n(row, 'amountPaise'),
          max,
          _green,
          money: true,
        ),
    ];
  }

  Widget _bar(
    String label,
    int value,
    int max,
    Color color, {
    bool money = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Flexible(flex: 2, child: Text(label)),
        Expanded(
          flex: 3,
          child: Container(
            height: 30,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              widthFactor: value <= 0 ? 0 : (value / max).clamp(0.02, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            money ? rupees(value) : '$value',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
  Widget _line(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: color,
          child: const Icon(Icons.trending_up, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const widths = [120.0, 240.0, 190.0, 260.0];
      final height = constraints.maxHeight;
      final count = height.isFinite
          ? (height / 38).floor().clamp(1, widths.length)
          : widths.length;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 16),
              child: Container(
                width: widths[i],
                height: height < 22 ? height : 22,
                decoration: BoxDecoration(
                  color: PgTheme.skeletonBase(context),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Loading analytics',
      child: ExcludeSemantics(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final height in [56.0, 180.0, 230.0])
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) => Container(
                  height: height,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PgTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment(
                        -1.5 + (reduceMotion ? 0 : controller.value * 3),
                        0,
                      ),
                      end: Alignment(
                        -0.5 + (reduceMotion ? 0 : controller.value * 3),
                        0,
                      ),
                      colors: [
                        PgTheme.skeletonBase(context),
                        PgTheme.skeletonHighlight(context),
                        PgTheme.skeletonBase(context),
                      ],
                    ).createShader(bounds),
                    child: const _SkeletonLines(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
