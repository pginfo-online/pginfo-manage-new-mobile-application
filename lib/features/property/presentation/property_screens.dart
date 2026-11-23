import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/design_system/theme.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

final roomFilterProvider = NotifierProvider<RoomFilter, Set<String>>(
  RoomFilter.new,
);

class RoomFilter extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void toggle(String value) {
    final next = {...state};
    next.contains(value) ? next.remove(value) : next.add(value);
    state = next;
  }

  void clear() => state = {};
}

class PropertyScreen extends ConsumerStatefulWidget {
  const PropertyScreen({super.key});
  @override
  ConsumerState<PropertyScreen> createState() => _PropertyState();
}

class _PropertyState extends ConsumerState<PropertyScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final propertyId = ref.watch(selectedPropertyProvider);
    final roomValue = ref.watch(roomsProvider);
    final filters = ref.watch(roomFilterProvider);
    return Scaffold(
      appBar: const PgHeader(),
      floatingActionButton: propertyId == null
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/rooms/new'),
              child: const Icon(Icons.add),
            ),
      body: propertyId == null
          ? Center(
              child: FilledButton(
                onPressed: () => context.push('/properties/select'),
                child: const Text('Select a property'),
              ),
            )
          : RefreshIndicator(
              color: PgTheme.blue,
              onRefresh: () async {
                await Future.wait([
                  ref.read(roomsProvider.notifier).refresh(),
                  ref.refresh(propertiesProvider.future),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SearchField(
                    hint: 'Search rooms',
                    onChanged: (v) => setState(() => search = v),
                    trailing: IconButton(
                      onPressed: () => context.push('/rooms/filter'),
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                        child: PgAsync(
                          value: roomValue,
                          retry: () => ref.invalidate(roomsProvider),
                          data: (rooms) => MetricCard(
                            label: 'Total rooms',
                            value: '${rooms.length}',
                            icon: Icons.meeting_room_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PgAsync(
                    value: roomValue,
                    retry: () => ref.invalidate(roomsProvider),
                    data: (rooms) {
                      const sharingOptions = {
                        'SINGLE',
                        'DOUBLE',
                        'TRIPLE',
                        'FOUR_SHARING',
                        'FIVE_SHARING',
                        'SIX_SHARING',
                      };
                      const statusOptions = {
                        'AVAILABLE',
                        'OCCUPIED',
                        'PARTIALLY_OCCUPIED',
                        'UNDER_MAINTENANCE',
                      };
                      const genderOptions = {'MALE', 'FEMALE', 'UNISEX'};
                      const vacancyOptions = {
                        'VACANT_BEDS',
                        'NO_VACANCY',
                        'PUBLISHED',
                      };
                      final sharing = filters.intersection(sharingOptions);
                      final statuses = filters.intersection(statusOptions);
                      final genders = filters.intersection(genderOptions);
                      final vacancy = filters.intersection(vacancyOptions);
                      final visible = rooms
                          .where(
                            (r) =>
                                r.roomNumber.toLowerCase().contains(
                                  search.toLowerCase(),
                                ) &&
                                (sharing.isEmpty ||
                                    sharing.contains(r.sharingType)) &&
                                (statuses.isEmpty ||
                                    statuses.contains(r.status)) &&
                                (genders.isEmpty ||
                                    genders.contains(r.gender)) &&
                                (vacancy.isEmpty ||
                                    (vacancy.contains('VACANT_BEDS') &&
                                        r.beds.any(
                                          (bed) => bed.status == 'AVAILABLE',
                                        )) ||
                                    (vacancy.contains('NO_VACANCY') &&
                                        r.beds.isNotEmpty &&
                                        r.beds.every(
                                          (bed) => bed.status != 'AVAILABLE',
                                        )) ||
                                    (vacancy.contains('PUBLISHED') &&
                                        r.isPublished)),
                          )
                          .toList();
                      if (visible.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'No rooms match your search or filters',
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${visible.length} rooms',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final room in visible) _RoomCard(room),
                          if (ref.read(roomsProvider.notifier).hasMore)
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    ref.read(roomsProvider.notifier).loadMore(),
                                child: const Text('Load more rooms'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard(this.room);
  final Room room;
  @override
  Widget build(BuildContext context) {
    final occupied = room.beds.where((b) => b.status == 'OCCUPIED').length;
    return PgCard(
      onTap: () => context.push('/rooms/${room.id}'),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: room.images.isEmpty
                      ? ColoredBox(
                          color: PgTheme.subtleHeaderBg(context),
                          child: const Icon(
                            Icons.bed_outlined,
                            color: Color(0xff2563eb),
                          ),
                        )
                      : Image.network(
                          room.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: PgTheme.subtleHeaderBg(context),
                            child: const Icon(
                              Icons.bed_outlined,
                              color: Color(0xff2563eb),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${rupees(room.rentAmount)}/bed • ${room.sharingType.replaceAll('_', ' ')}',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Text('$occupied occupied'),
              const SizedBox(width: 16),
              Text('${room.beds.length - occupied} vacant'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/tenants/new'),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add tenant'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PropertySelectScreen extends ConsumerStatefulWidget {
  const PropertySelectScreen({super.key});

  @override
  ConsumerState<PropertySelectScreen> createState() => _PropertySelectState();
}

class _PropertySelectState extends ConsumerState<PropertySelectScreen> {
  double drag = 0;
  String query = '';
  bool selecting = false;

  void close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> select(String id) async {
    if (selecting) return;
    setState(() => selecting = true);
    try {
      await ref.read(selectedPropertyProvider.notifier).select(id);
      if (!mounted) return;
      ref.read(roomSearchProvider.notifier).set('');
      ref.read(roomFloorProvider.notifier).set(null);
      close();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final selected = ref.watch(selectedPropertyProvider);
    return Scaffold(
      appBar: const PgHeader(title: 'Select property'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/properties/new'),
        icon: const Icon(Icons.add),
        label: const Text('New property'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => drag = 0,
        onHorizontalDragUpdate: (details) => drag += details.primaryDelta ?? 0,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (!selecting && (drag < -60 || (drag < -16 && velocity < -250))) {
            close();
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchField(
                hint: 'Search properties',
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: PgAsync(
                value: properties,
                retry: () => ref.invalidate(propertiesProvider),
                placeholder: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (var i = 0; i < 4; i++)
                      const PgCard(child: PgSkeleton(height: 52)),
                  ],
                ),
                data: (items) {
                  final visible = items
                      .where(
                        (item) => '${item.name} ${item.city ?? ''} ${item.type}'
                            .toLowerCase()
                            .contains(query),
                      )
                      .toList();
                  if (visible.isEmpty) {
                    return Center(
                      child: Text(
                        items.isEmpty
                            ? 'Add your first property to get started.'
                            : 'No properties match your search.',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final property = visible[index];
                      final active = property.id == selected;
                      return PgCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          selected: active,
                          enabled: !selecting,
                          leading: const CircleAvatar(
                            child: Icon(Icons.apartment),
                          ),
                          title: Text(property.name),
                          subtitle: Text(
                            [
                              property.type,
                              if (property.city?.isNotEmpty == true)
                                property.city!,
                            ].join(' · '),
                          ),
                          trailing: Icon(
                            active ? Icons.check_circle : Icons.chevron_right,
                          ),
                          onTap: () => select(property.id),
                        ),
                      );
                    },
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

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key});
  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormState();
}

class _PropertyFormState extends ConsumerState<PropertyFormScreen> {
  final form = GlobalKey<FormState>();
  final fields = {
    for (final key in [
      'name',
      'ownerName',
      'addressLine1',
      'city',
      'state',
      'pincode',
      'contactPhone',
      'contactEmail',
    ])
      key: TextEditingController(),
  };
  String type = 'PG';
  bool busy = false;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final body = <String, dynamic>{
        'type': type,
        for (final key in fields.keys)
          if (fields[key]!.text.trim().isNotEmpty)
            key: fields[key]!.text.trim(),
      };
      final property = await ref
          .read(operationsViewModelProvider)
          .createProperty(body);
      await ref.read(selectedPropertyProvider.notifier).select(property.id);
      ref.invalidate(propertiesProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) context.go('/property');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PgHeader(title: 'Add property'),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PgField(
            'Property name',
            controller: fields['name'],
            validator: requiredText,
          ),
          PgField(
            'Owner name',
            controller: fields['ownerName'],
            validator: requiredText,
          ),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Property type'),
            items:
                [
                      'PG',
                      'HOSTEL',
                      'CO_LIVING',
                      'FLAT',
                      'APARTMENT',
                      'RK',
                      'OTHER',
                    ]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => type = v!),
          ),
          const SizedBox(height: 12),
          PgField(
            'Address',
            controller: fields['addressLine1'],
            validator: requiredText,
          ),
          PgField('City', controller: fields['city'], validator: requiredText),
          PgField(
            'State',
            controller: fields['state'],
            validator: requiredText,
          ),
          PgField(
            'Pincode',
            controller: fields['pincode'],
            keyboardType: TextInputType.number,
            validator: (v) => RegExp(r'^[1-9][0-9]{5}$').hasMatch(v ?? '')
                ? null
                : 'Enter a 6-digit pincode',
          ),
          PgField(
            'Contact phone',
            controller: fields['contactPhone'],
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? null : mobileValidator(v),
          ),
          PgField(
            'Contact email',
            controller: fields['contactEmail'],
            keyboardType: TextInputType.emailAddress,
          ),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Saving…' : 'Add property'),
          ),
        ],
      ),
    ),
  );
}

class RoomFilterScreen extends ConsumerStatefulWidget {
  const RoomFilterScreen({super.key});
  @override
  ConsumerState<RoomFilterScreen> createState() => _RoomFilterState();
}

class _RoomFilterState extends ConsumerState<RoomFilterScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(roomFilterProvider);
    final groups = {
      'Sharing type': [
        'SINGLE',
        'DOUBLE',
        'TRIPLE',
        'FOUR_SHARING',
        'FIVE_SHARING',
        'SIX_SHARING',
        'SEVEN_SHARING',
        'EIGHT_SHARING',
        'NINE_SHARING',
        'TEN_SHARING',
      ],
      'Room status': [
        'AVAILABLE',
        'OCCUPIED',
        'PARTIALLY_OCCUPIED',
        'UNDER_MAINTENANCE',
      ],
      'Vacancy': ['VACANT_BEDS', 'NO_VACANCY', 'PUBLISHED'],
      'Gender': ['MALE', 'FEMALE', 'UNISEX'],
    };
    return Scaffold(
      appBar: const PgHeader(title: 'Room filter'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              hint: 'Search filters',
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final option in entry.value)
                    if (option.toLowerCase().contains(search.toLowerCase()))
                      CheckboxListTile(
                        title: Text(option.replaceAll('_', ' ')),
                        value: selected.contains(option),
                        onChanged: (_) => ref
                            .read(roomFilterProvider.notifier)
                            .toggle(option),
                      ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(roomFilterProvider.notifier).clear(),
                      child: const Text('Clear all'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomFormScreen extends ConsumerStatefulWidget {
  const RoomFormScreen({super.key});
  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<RoomFormScreen> {
  final form = GlobalKey<FormState>();
  final number = TextEditingController(),
      floor = TextEditingController(),
      rent = TextEditingController(),
      beds = TextEditingController(text: '1'),
      amenities = TextEditingController(),
      description = TextEditingController();
  String sharing = 'SINGLE';
  String gender = 'UNISEX';
  bool busy = false;
  @override
  void dispose() {
    number.dispose();
    floor.dispose();
    rent.dispose();
    beds.dispose();
    amenities.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final id = ref.read(selectedPropertyProvider);
    if (id == null) return;
    setState(() => busy = true);
    try {
      await ref.read(operationsViewModelProvider).createRoom(id, {
        'roomNumber': number.text.trim(),
        'floor': floor.text.trim().isEmpty ? '0' : floor.text.trim(),
        'sharingType': sharing,
        'rentAmount': parseRupees(rent.text),
        'initialBedCount': int.parse(beds.text),
        'gender': gender,
        'amenities': amenities.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
      });
      ref.invalidate(roomsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PgHeader(title: 'Add room'),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PgField('Room number', controller: number, validator: requiredText),
          PgField('Floor', controller: floor),
          DropdownButtonFormField<String>(
            initialValue: sharing,
            decoration: const InputDecoration(labelText: 'Sharing type'),
            items:
                [
                      'SINGLE',
                      'DOUBLE',
                      'TRIPLE',
                      'FOUR_SHARING',
                      'FIVE_SHARING',
                      'SIX_SHARING',
                    ]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => sharing = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender preference'),
            items: ['UNISEX', 'MALE', 'FEMALE']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => gender = value!),
          ),
          const SizedBox(height: 12),
          PgField(
            'Monthly rent per bed (₹)',
            controller: rent,
            keyboardType: TextInputType.number,
            validator: (v) =>
                (tryParseRupees(v) ?? 0) > 0 ? null : 'Enter a positive amount',
          ),
          PgField(
            'Number of beds',
            controller: beds,
            keyboardType: TextInputType.number,
            validator: (v) =>
                (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter bed count',
          ),
          PgField('Amenities (comma separated)', controller: amenities),
          PgField('Description', controller: description, maxLines: 3),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Saving…' : 'Add room'),
          ),
        ],
      ),
    ),
  );
}

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PgAsync(
    value: ref.watch(roomProvider(id)),
    retry: () => ref.invalidate(roomProvider(id)),
    data: (room) => DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room ${room.roomNumber}'),
              if (room.property != null)
                Text(
                  room.property!.name,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tenants'),
              Tab(text: 'Details'),
              Tab(text: 'Activity'),
            ],
            isScrollable: true,
          ),
        ),
        body: TabBarView(
          children: [
            Consumer(
              builder: (context, ref, _) => PgAsync(
                value: ref.watch(residentsProvider),
                data: (people) {
                  final tenants = people.where((p) => p.roomId == id).toList();
                  return ListView(
                    children: [
                      for (final person in tenants)
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            '${person.firstName} ${person.lastName ?? ''}',
                          ),
                          subtitle: Text(rupees(person.monthlyRent)),
                          onTap: () => context.push('/tenants/${person.id}'),
                        ),
                      if (tenants.isEmpty)
                        const ListTile(title: Text('No tenants in this room')),
                    ],
                  );
                },
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MetricCard(
                  label: 'Monthly rent',
                  value: rupees(room.rentAmount),
                ),
                ListTile(
                  title: Text(
                    'Sharing: ${room.sharingType.replaceAll('_', ' ')}',
                  ),
                ),
                ListTile(title: Text('Status: ${room.status}')),
                for (final bed in room.beds)
                  ListTile(
                    leading: const Icon(Icons.bed_outlined),
                    title: Text('Bed ${bed.bedNumber}'),
                    subtitle: Text(bed.status),
                  ),
              ],
            ),
            _RoomActivity(id),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/tenants/new'),
          icon: const Icon(Icons.person_add),
          label: const Text('Add tenant'),
        ),
      ),
    ),
  );
}

class _RoomActivity extends ConsumerWidget {
  const _RoomActivity(this.roomId);
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PgAsync(
    value: ref.watch(activityProvider((entityType: 'Room', entityId: roomId))),
    data: (events) {
      if (events.isEmpty) {
        return const Center(child: Text('No activity recorded yet'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return PgCard(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text('${event['action']}'.replaceAll('.', ' ')),
              subtitle: Text('${event['createdAt']}'),
            ),
          );
        },
      );
    },
  );
}
