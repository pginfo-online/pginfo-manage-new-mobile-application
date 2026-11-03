import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late DateTime period;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    period = DateTime(now.year, now.month);
  }

  Future<void> choosePeriod() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: period,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Select any day in the reporting month',
    );
    if (selected != null && mounted) {
      setState(() => period = DateTime(selected.year, selected.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = (
      propertyId: ref.watch(selectedPropertyProvider),
      month: period.month,
      year: period.year,
    );
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Birds eye'),
              Tab(text: 'Financials'),
              Tab(text: 'Occupancy'),
              Tab(text: 'Tenants'),
              Tab(text: 'Issues'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reporting period',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: choosePeriod,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(DateFormat.yMMMM().format(period)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PgAsync(
                value: ref.watch(dashboardPeriodProvider(query)),
                retry: () => ref.invalidate(dashboardPeriodProvider(query)),
                data: (data) {
                  final op = data['operational'] as Map<String, dynamic>,
                      fin = data['financial'] as Map<String, dynamic>;
                  Widget metrics(List<(String, String)> entries) =>
                      GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 230,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: entries.length,
                        itemBuilder: (context, index) => MetricCard(
                          label: entries[index].$1,
                          value: entries[index].$2,
                        ),
                      );
                  return TabBarView(
                    children: [
                      metrics([
                        ('Occupied beds', '${op['occupiedBeds']}'),
                        (
                          'Total collection',
                          rupees(fin['totalCollectedPaise'] as num),
                        ),
                        (
                          'Selected month',
                          rupees(fin['monthCollectedPaise'] as num),
                        ),
                        (
                          'Total dues',
                          rupees(fin['outstandingBalancePaise'] as num),
                        ),
                        (
                          'Selected month dues',
                          rupees(fin['monthOutstandingPaise'] as num),
                        ),
                        ('Expenses', rupees(fin['totalExpensesPaise'] as num)),
                        (
                          'Deposits held',
                          rupees(fin['securityDepositsHeldPaise'] as num),
                        ),
                        (
                          'Pending deposits',
                          rupees(fin['pendingDepositsPaise'] as num),
                        ),
                        ('Total rooms', '${op['totalRooms']}'),
                        ('Complaints', '${op['pendingComplaints']}'),
                      ]),
                      metrics([
                        (
                          'Today collected',
                          rupees(fin['todayCollectedPaise'] as num),
                        ),
                        (
                          'Period collected',
                          rupees(fin['monthCollectedPaise'] as num),
                        ),
                        (
                          'Period billed',
                          rupees(fin['monthBilledPaise'] as num),
                        ),
                        (
                          'Outstanding',
                          rupees(fin['outstandingBalancePaise'] as num),
                        ),
                        (
                          'Net cashflow',
                          rupees(fin['netCashflowPaise'] as num),
                        ),
                        (
                          'Period expenses',
                          rupees(fin['monthExpensesPaise'] as num),
                        ),
                      ]),
                      metrics([
                        ('Rentable beds', '${op['totalBeds']}'),
                        ('Occupied beds', '${op['occupiedBeds']}'),
                        ('Available beds', '${op['availableBeds']}'),
                        ('Occupancy rate', '${op['occupancyRate']}%'),
                      ]),
                      metrics([
                        ('Current tenants', '${op['currentResidents']}'),
                        ('Upcoming move-ins', '${op['upcomingMoveIns']}'),
                        ('Period move-ins', '${op['periodMoveIns']}'),
                        ('Period move-outs', '${op['periodMoveOuts']}'),
                      ]),
                      metrics([
                        ('Pending complaints', '${op['pendingComplaints']}'),
                        ('Issues created', '${op['periodComplaintsCreated']}'),
                        (
                          'Issues resolved',
                          '${op['periodComplaintsResolved']}',
                        ),
                      ]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
