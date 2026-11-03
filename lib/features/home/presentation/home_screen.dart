import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardProvider);
    final selected = ref.watch(selectedPropertyProvider);
    return Scaffold(
      appBar: PgHeader(
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            onPressed: () => context.push('/action/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 550) context.push('/profile');
        },
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(dashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SearchField(
                hint: 'Search anything',
                trailing: IconButton(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.arrow_forward),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty) context.push('/search');
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              PgAsync(
                value: metrics,
                retry: () => ref.invalidate(dashboardProvider),
                data: (data) {
                  final financial = data['financial'] as Map<String, dynamic>;
                  return Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'View analytics dashboard',
                          value: 'Insights',
                          icon: Icons.auto_graph,
                          onTap: () => context.push('/analytics'),
                        ),
                      ),
                      Expanded(
                        child: MetricCard(
                          label: "Today's collection",
                          value: rupees(
                            financial['todayCollectedPaise'] as num,
                          ),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quick actions',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/all'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _QuickAction(
                    'Add tenant',
                    Icons.person_add_alt_1,
                    '/tenants/new',
                  ),
                  _QuickAction(
                    'Complaints',
                    Icons.report_problem_outlined,
                    '/action/complaints',
                  ),
                  _QuickAction(
                    'Collect payment',
                    Icons.payments_outlined,
                    '/action/collect',
                  ),
                  _QuickAction(
                    'Announcements',
                    Icons.send_outlined,
                    '/action/announcements',
                  ),
                  _QuickAction(
                    'Add expense',
                    Icons.receipt_long_outlined,
                    '/action/expense',
                  ),
                  _QuickAction(
                    'Add due',
                    Icons.note_add_outlined,
                    '/action/due',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PgCard(
                onTap: () => context.push('/properties/select'),
                child: Row(
                  children: [
                    const Icon(Icons.apartment, color: Color(0xff3156f5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selected == null
                            ? 'Choose or add a property'
                            : 'Manage selected property',
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.label, this.icon, this.path);
  final String label, path;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 56) / 3,
    child: InkWell(
      onTap: () => context.push(path),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xffe4eaff),
            child: Icon(icon, color: const Color(0xff3156f5)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const PgHeader(title: 'Profile & settings'),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.apartment_outlined),
          title: const Text('Switch property'),
          onTap: () => context.push('/properties/select'),
        ),
        ListTile(
          leading: const Icon(Icons.business_outlined),
          title: const Text('Switch organization'),
          onTap: () => context.push('/organizations/select'),
        ),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Team access'),
          onTap: () => context.push('/action/team'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () async {
            await ref.read(authRepositoryProvider).logout();
            ref.read(selectedPropertyProvider.notifier).select(null);
            ref.read(selectedOrganizationProvider.notifier).select(null);
            ref.invalidate(sessionProvider);
            ref.invalidate(propertiesProvider);
            ref.invalidate(dashboardProvider);
            ref.invalidate(roomsProvider);
            ref.invalidate(residentsProvider);
            ref.invalidate(globalSearchProvider);
            ref.invalidate(tenantLedgerProvider);
            ref.invalidate(membersProvider);
            ref.invalidate(organizationsProvider);
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    ),
  );
}

class OrganizationSelectScreen extends ConsumerWidget {
  const OrganizationSelectScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const PgHeader(title: 'Switch organization'),
    body: PgAsync(
      value: ref.watch(organizationsProvider),
      retry: () => ref.invalidate(organizationsProvider),
      data: (items) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final org in items)
            PgCard(
              onTap: () async {
                try {
                  await ref
                      .read(operationsViewModelProvider)
                      .switchOrganization(org['id'] as String);
                  ref
                      .read(selectedOrganizationProvider.notifier)
                      .select(org['id'] as String);
                  ref.read(selectedPropertyProvider.notifier).select(null);
                  ref.invalidate(propertiesProvider);
                  ref.invalidate(roomsProvider);
                  ref.invalidate(residentsProvider);
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(globalSearchProvider);
                  ref.invalidate(tenantLedgerProvider);
                  ref.invalidate(membersProvider);
                  if (context.mounted) context.go('/home');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              child: ListTile(
                title: Text('${org['name']}'),
                subtitle: Text('Role: ${org['role']}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
        ],
      ),
    ),
  );
}

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends ConsumerState<GlobalSearchScreen> {
  String query = '';
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PgHeader(title: 'Search'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SearchField(
          hint: 'Search across PgInfo',
          onChanged: (v) {
            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => query = v.trim());
            });
          },
        ),
        const SizedBox(height: 20),
        if (query.isEmpty) ...[
          for (final item in [
            'Tenants',
            'Rooms',
            'Dues',
            'Collections',
            'Complaints',
            'Reports',
          ])
            ListTile(
              title: Text(item),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(
                item == 'Tenants'
                    ? '/people'
                    : item == 'Rooms'
                    ? '/property'
                    : item == 'Complaints'
                    ? '/action/complaints'
                    : '/money',
              ),
            ),
        ] else
          PgAsync(
            value: ref.watch(globalSearchProvider(query)),
            data: (results) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in results.entries)
                  if (entry.value.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final item in entry.value)
                      ListTile(
                        title: Text(
                          '${item['name'] ?? item['firstName'] ?? item['description'] ?? 'Result'}',
                        ),
                        subtitle: Text(
                          '${item['mobile'] ?? item['status'] ?? ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final id = item['id'];
                          if (entry.key == 'Tenants') {
                            context.push('/tenants/$id');
                          } else if (entry.key == 'Rooms') {
                            context.push('/rooms/$id');
                          } else {
                            context.push('/action/${entry.key.toLowerCase()}');
                          }
                        },
                      ),
                  ],
              ],
            ),
          ),
      ],
    ),
  );
}
