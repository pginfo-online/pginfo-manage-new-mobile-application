import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});
  @override
  ConsumerState<PeopleScreen> createState() => _PeopleState();
}

class _PeopleState extends ConsumerState<PeopleScreen>
    with SingleTickerProviderStateMixin {
  late final tabs = TabController(length: 3, vsync: this, initialIndex: 1);
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('People'),
      bottom: TabBar(
        controller: tabs,
        tabs: const [
          Tab(text: 'Leads'),
          Tab(text: 'Tenants'),
          Tab(text: 'Team'),
        ],
      ),
    ),
    body: TabBarView(
      controller: tabs,
      children: const [_LeadsTab(), _TenantsTab(), _TeamTab()],
    ),
  );
}

class _TenantsTab extends ConsumerStatefulWidget {
  const _TenantsTab();
  @override
  ConsumerState<_TenantsTab> createState() => _TenantsState();
}

class _TenantsState extends ConsumerState<_TenantsTab> {
  String search = '';
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = PagedQuery(
      path: '/residents',
      propertyId: ref.watch(selectedPropertyProvider),
      search: search,
    );
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pagedListProvider(query));
            await ref.read(pagedListProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SearchField(
                hint: 'Search tenants',
                onChanged: (v) {
                  debounce?.cancel();
                  debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => mounted ? setState(() => search = v) : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              PgCard(
                child: Row(
                  children: [
                    const Icon(Icons.task_alt),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Tasks pending')),
                    TextButton(
                      onPressed: () => context.push('/action/complaints'),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
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
                      data: (data) => MetricCard(
                        label: 'Total tenants',
                        value:
                            '${(data['operational'] as Map)['currentResidents']}',
                        icon: Icons.people_outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PgAsync(
                value: ref.watch(pagedListProvider(query)),
                retry: () => ref.invalidate(pagedListProvider(query)),
                data: (items) {
                  final visible = items.map(Resident.fromJson).toList();
                  return Column(
                    children: [
                      for (final p in visible) _TenantCard(p),
                      if (ref.read(pagedListProvider(query).notifier).hasMore)
                        TextButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(pagedListProvider(query).notifier)
                                  .loadMore();
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
                          child: const Text('Load more tenants'),
                        ),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No tenants found'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => context.push('/tenants/new'),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard(this.person);
  final Resident person;
  @override
  Widget build(BuildContext context) => PgCard(
    onTap: () => context.push('/tenants/${person.id}'),
    child: Column(
      children: [
        Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${person.firstName} ${person.lastName ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Rent: ${rupees(person.monthlyRent)}'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Call',
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: person.mobile)),
              icon: const Icon(Icons.call_outlined),
            ),
            IconButton(
              tooltip: 'WhatsApp',
              onPressed: () =>
                  context.push('/action/message?residentId=${person.id}'),
              icon: const Icon(Icons.chat_outlined),
            ),
          ],
        ),
        const Divider(),
        Row(
          children: [
            Text('Dues: ${rupees(person.dues)}'),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  context.push('/action/due?residentId=${person.id}'),
              icon: const Icon(Icons.add),
              label: const Text('Add due'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LeadsTab extends ConsumerStatefulWidget {
  const _LeadsTab();
  @override
  ConsumerState<_LeadsTab> createState() => _LeadsState();
}

class _LeadsState extends ConsumerState<_LeadsTab> {
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
      path: '/leads',
      propertyId: property,
      search: search,
      status: status == 'All' ? null : status,
    );
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SearchField(
              hint: 'Search leads',
              onChanged: (v) {
                debounce?.cancel();
                debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => mounted ? setState(() => search = v) : null,
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  ['All', 'NEW', 'CONTACTED', 'VISITED', 'CONVERTED', 'LOST']
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value),
                          selected: status == value,
                          onSelected: (_) => setState(() => status = value),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 8),
            PgAsync(
              value: ref.watch(leadStatsProvider),
              retry: () => ref.invalidate(leadStatsProvider),
              data: (stats) {
                final byStatus = stats['byStatus'] as Map? ?? const {};
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  children: [
                    MetricCard(
                      label: 'Total leads',
                      value: '${stats['total']}',
                    ),
                    MetricCard(
                      label: 'New leads',
                      value: '${byStatus['NEW'] ?? 0}',
                    ),
                    MetricCard(
                      label: 'Visited',
                      value: '${byStatus['VISITED'] ?? 0}',
                    ),
                    MetricCard(
                      label: 'Conversion',
                      value: '${stats['conversionRate']}%',
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
                    label: 'Leads loaded',
                    value: '${items.length}',
                    icon: Icons.person_search,
                  ),
                  for (final lead in items)
                    PgCard(
                      child: ListTile(
                        title: Text('${lead['name']}'),
                        subtitle: Text('${lead['mobile']} • ${lead['status']}'),
                        onTap: () =>
                            context.push('/action/lead?id=${lead['id']}'),
                      ),
                    ),
                  if (ref.read(pagedListProvider(query).notifier).hasMore)
                    TextButton(
                      onPressed: () => ref
                          .read(pagedListProvider(query).notifier)
                          .loadMore(),
                      child: const Text('Load more leads'),
                    ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => context.push('/action/lead'),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TeamTab extends ConsumerStatefulWidget {
  const _TeamTab();
  @override
  ConsumerState<_TeamTab> createState() => _TeamState();
}

class _TeamState extends ConsumerState<_TeamTab> {
  String search = '';
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgs = ref.watch(organizationsProvider).asData?.value ?? [];
    final orgId =
        ref.watch(selectedOrganizationProvider) ??
        (orgs.isEmpty ? null : orgs.first['id'] as String);
    final staffQuery = PagedQuery(
      path: '/staff',
      propertyId: ref.watch(selectedPropertyProvider),
      search: search,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SearchField(
          hint: 'Search team',
          onChanged: (value) {
            debounce?.cancel();
            debounce = Timer(
              const Duration(milliseconds: 350),
              () => mounted ? setState(() => search = value) : null,
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/action/team'),
          icon: const Icon(Icons.add),
          label: const Text('Add member'),
        ),
        const SizedBox(height: 16),
        Text(
          'Organization access',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (orgId == null)
          const ListTile(title: Text('No organization selected'))
        else
          PgAsync(
            value: ref.watch(membersProvider(orgId)),
            retry: () => ref.invalidate(membersProvider(orgId)),
            data: (members) => Column(
              children: [
                for (final member in members)
                  PgCard(
                    child: ListTile(
                      title: Text(
                        '${(member['user'] as Map?)?['firstName'] ?? ''} ${(member['user'] as Map?)?['lastName'] ?? ''}',
                      ),
                      subtitle: Text(
                        '${(member['user'] as Map?)?['email'] ?? ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Change access',
                        initialValue: member['role'] as String?,
                        onSelected: (role) async {
                          try {
                            if (role == 'REMOVE') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove team member?'),
                                  content: const Text(
                                    'Their organization access will be revoked immediately.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => context.pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => context.pop(true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              await ref
                                  .read(operationsViewModelProvider)
                                  .delete(
                                    '/organizations/$orgId/members/${member['id']}',
                                  );
                            } else {
                              await ref.read(operationsViewModelProvider).update(
                                '/organizations/$orgId/members/${member['id']}',
                                {'role': role},
                              );
                            }
                            ref.invalidate(membersProvider(orgId));
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          }
                        },
                        itemBuilder: (_) =>
                            ['ADMIN', 'MANAGER', 'STAFF', 'VIEWER', 'REMOVE']
                                .map(
                                  (role) => PopupMenuItem(
                                    value: role,
                                    child: Text(
                                      role == 'REMOVE' ? 'Remove access' : role,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Property staff',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: ref.watch(selectedPropertyProvider) == null
                  ? null
                  : () => context.push('/action/staff'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add staff'),
            ),
          ],
        ),
        PgAsync(
          value: ref.watch(pagedListProvider(staffQuery)),
          retry: () => ref.invalidate(pagedListProvider(staffQuery)),
          data: (staffMembers) => Column(
            children: [
              for (final staff in staffMembers)
                PgCard(
                  onTap: () => context.push('/action/staff?id=${staff['id']}'),
                  child: ListTile(
                    title: Text(
                      '${staff['firstName']} ${staff['lastName'] ?? ''}',
                    ),
                    subtitle: Text('${staff['mobile']}'),
                  ),
                ),
              if (ref.read(pagedListProvider(staffQuery).notifier).hasMore)
                TextButton(
                  onPressed: () => ref
                      .read(pagedListProvider(staffQuery).notifier)
                      .loadMore(),
                  child: const Text('Load more staff'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
