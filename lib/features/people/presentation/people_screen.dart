import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';
import '../../tenants/presentation/tenant_actions.dart';
import '../../tenants/presentation/tenant_skeleton.dart';

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
    appBar: PgHeader(
      showProperty: true,
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
  String? status;
  Timer? debounce;
  bool selecting = false, busy = false;
  final selected = <String>{};

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  Future<void> bulkMoveOut() async {
    final archive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${selected.length} tenants'),
        content: const Text(
          'Move tenants out to release their beds. Archive also hides their profiles from People and retains their history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Move out'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (archive == null || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(operationsViewModelProvider).create(
        '/residents/bulk-move-out',
        {'residentIds': selected.toList(), 'archive': archive},
      );
      if (!mounted) return;
      setState(() {
        selected.clear();
        selecting = false;
      });
      ref.invalidate(pagedListProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(dashboardProvider);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> more() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('More Actions')),
            for (final (key, icon, title) in const [
              ('add', Icons.person_add_alt_1, 'Add a Single Tenant'),
              ('autopay', Icons.autorenew, 'Send Bulk Autopay Reminders'),
              ('report', Icons.download, 'Download Tenant Report'),
              (
                'whatsapp',
                Icons.chat_outlined,
                'Send Bulk WhatsApp Payment Reminders',
              ),
              ('bulk', Icons.delete_outline, 'Bulk Eviction/Delete Tenants'),
            ])
              ListTile(
                leading: Icon(icon),
                trailing: const Icon(Icons.chevron_right),
                title: Text(title),
                onTap: () => Navigator.pop(context, key),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'add':
        context.push('/tenants/new');
      case 'autopay':
        context.push('/action/reminders?kind=autopay');
      case 'report':
        final property = ref.read(selectedPropertyProvider);
        context.push(
          Uri(
            path: '/action/report',
            queryParameters: {'type': 'residents', 'propertyId': ?property},
          ).toString(),
        );
      case 'whatsapp':
        context.push('/action/reminders?kind=whatsapp');
      case 'bulk':
        setState(() => selecting = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = ref.watch(selectedPropertyProvider);
    ref.listen(selectedPropertyProvider, (_, _) {
      setState(() {
        selected.clear();
        selecting = false;
      });
    });
    final query = PagedQuery(
      path: '/residents',
      propertyId: propertyId,
      search: search,
      status: status,
    );
    final provider = pagedListProvider(query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: 'Search tenants',
                  onChanged: (value) {
                    debounce?.cancel();
                    debounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => search = value.trim());
                    });
                  },
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Filter tenants',
                icon: Icon(
                  status == null ? Icons.filter_list : Icons.filter_alt,
                ),
                onSelected: (value) =>
                    setState(() => status = value.isEmpty ? null : value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: '', child: Text('All tenants')),
                  PopupMenuItem(value: 'ACTIVE', child: Text('Active')),
                  PopupMenuItem(
                    value: 'NOTICE_PERIOD',
                    child: Text('On notice'),
                  ),
                  PopupMenuItem(
                    value: 'PENDING_MOVE_IN',
                    child: Text('Pending move-in'),
                  ),
                  PopupMenuItem(value: 'MOVED_OUT', child: Text('Moved out')),
                ],
              ),
              IconButton(
                tooltip: 'More actions',
                onPressed: busy ? null : more,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        if (selecting)
          ListTile(
            title: Text('${selected.length} selected'),
            leading: IconButton(
              tooltip: 'Cancel selection',
              onPressed: busy
                  ? null
                  : () => setState(() {
                      selected.clear();
                      selecting = false;
                    }),
              icon: const Icon(Icons.close),
            ),
            trailing: FilledButton(
              onPressed: busy || selected.isEmpty ? null : bulkMoveOut,
              child: Text(busy ? 'Saving…' : 'Continue'),
            ),
          ),
        Expanded(
          child: PgAsync(
            value: ref.watch(provider),
            placeholder: const SingleChildScrollView(
              child: TenantSkeleton(TenantPlaceholder.cards),
            ),
            retry: () => ref.invalidate(provider),
            data: (items) => RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: ListView.builder(
                key: PageStorageKey(query),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No tenants found')),
                      );
                    }
                    if (!ref.read(provider.notifier).hasMore) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(provider.notifier).loadMore();
                        } catch (error) {
                          if (context.mounted) showError(context, error);
                        }
                      },
                      child: const Text('Load more tenants'),
                    );
                  }
                  final person = Resident.fromJson(items[index]);
                  if (!selecting) {
                    return _TenantCard(person, key: ValueKey(person.id));
                  }
                  return CheckboxListTile(
                    key: ValueKey(person.id),
                    value: selected.contains(person.id),
                    title: Text(
                      '${person.firstName} ${person.lastName ?? ''}'.trim(),
                    ),
                    subtitle: Text(person.property?.name ?? ''),
                    onChanged: busy
                        ? null
                        : (value) {
                            if (value == true && selected.length >= 50) {
                              showError(
                                context,
                                'Select up to 50 tenants at a time',
                              );
                              return;
                            }
                            setState(() {
                              if (value == true) {
                                selected.add(person.id);
                              } else {
                                selected.remove(person.id);
                              }
                            });
                          },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard(this.person, {super.key});
  final Resident person;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          [
            person.property?.name,
            if (person.room != null) 'Room ${person.room!.roomNumber}',
            if (person.bed != null) 'Bed ${person.bed!.bedNumber}',
          ].nonNulls.join(' · '),
        ),
      ),
      TenantQuickActions(
        person: person,
        child: PgCard(
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
                    label: const Text('Due'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  person.autopayActive
                      ? '● Autopay active'
                      : '○ Autopay inactive',
                ),
              ),
            ],
          ),
        ),
      ),
    ],
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
              placeholder: const TenantSkeleton(TenantPlaceholder.fields),
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
              placeholder: const TenantSkeleton(TenantPlaceholder.cards),
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
            placeholder: const TenantSkeleton(TenantPlaceholder.cards),
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
          placeholder: const TenantSkeleton(TenantPlaceholder.cards),
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
