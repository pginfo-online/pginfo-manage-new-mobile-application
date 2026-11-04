import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/design_system/theme.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';
import 'property_screens.dart';

final _complaintsForProperty =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, propertyId) => ref
          .watch(repositoryProvider)
          .list('/complaints', query: {'propertyId': propertyId}),
    );

class PropertyDashboardScreen extends ConsumerStatefulWidget {
  const PropertyDashboardScreen({super.key});
  @override
  ConsumerState<PropertyDashboardScreen> createState() =>
      _PropertyDashboardState();
}

class _PropertyDashboardState extends ConsumerState<PropertyDashboardScreen> {
  Timer? searchTimer;
  @override
  void dispose() {
    searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = ref.watch(selectedPropertyProvider);
    final rooms = ref.watch(roomsProvider);
    final properties =
        ref.watch(propertiesProvider).asData?.value ?? <Property>[];
    final property = properties.where((p) => p.id == propertyId).firstOrNull;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: PgTheme.analyticsCanvas,
        appBar: AppBar(
          title: InkWell(
            onTap: () => context.push('/properties/select'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    property?.name ?? 'Select property',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xffb9c5fa),
            tabs: [
              Tab(text: 'Room'),
              Tab(text: 'Listing'),
              Tab(text: 'Complaint'),
              Tab(text: 'Food'),
            ],
          ),
        ),
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
            : TabBarView(
                children: [
                  _roomTab(propertyId, property, rooms),
                  _listingTab(rooms),
                  _complaintTab(propertyId),
                  const Center(
                    child: Text(
                      'No food service data is available for this property.',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _roomTab(
    String propertyId,
    Property? property,
    AsyncValue<List<Room>> roomValue,
  ) {
    final floor = ref.watch(roomFloorProvider);
    final filters = ref.watch(roomFilterProvider);
    final rooms = roomValue.asData?.value;
    final visible =
        rooms
            ?.where(
              (room) =>
                  (!filters.contains('VACANT_BEDS') ||
                      room.beds.any((bed) => bed.status == 'AVAILABLE')) &&
                  (!filters.contains('NO_VACANCY') ||
                      room.beds.every((bed) => bed.status != 'AVAILABLE')) &&
                  (!filters.contains('PUBLISHED') || room.isPublished) &&
                  (!filters.any(
                        (f) => const [
                          'AVAILABLE',
                          'OCCUPIED',
                          'PARTIALLY_OCCUPIED',
                          'UNDER_MAINTENANCE',
                        ].contains(f),
                      ) ||
                      filters.contains(room.status)) &&
                  (!filters.contains('MALE') &&
                          !filters.contains('FEMALE') &&
                          !filters.contains('UNISEX') ||
                      filters.contains(room.gender)) &&
                  (!filters.any(
                        (f) =>
                            f.endsWith('_SHARING') ||
                            ['SINGLE', 'DOUBLE', 'TRIPLE'].contains(f),
                      ) ||
                      filters.contains(room.sharingType)),
            )
            .toList() ??
        <Room>[];
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(roomsProvider);
        await ref.read(roomsProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) {
                  searchTimer?.cancel();
                  searchTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      ref.read(roomSearchProvider.notifier).set(value);
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search Rooms',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Filter rooms',
                    onPressed: () => context.push('/rooms/filter'),
                    icon: const Icon(Icons.filter_list),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 158,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  SizedBox(
                    width: 160,
                    child: _summaryCard(
                      'View Analytics Dashboard',
                      '↗',
                      onTap: () => context.push('/analytics'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: _summaryCard(
                      'Total Rooms',
                      property == null ? '…' : '${property.roomCount}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: const Text('Room'),
                    selected: floor == null,
                    onSelected: (_) =>
                        ref.read(roomFloorProvider.notifier).set(null),
                  ),
                  for (final choice in const [
                    ('Ground', '0'),
                    ('1st', '1'),
                    ('2nd', '2'),
                    ('3rd', '3'),
                    ('Basement', 'Basement'),
                  ]) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(choice.$1),
                      selected: floor == choice.$2,
                      onSelected: (_) =>
                          ref.read(roomFloorProvider.notifier).set(choice.$2),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (rooms == null && roomValue.isLoading)
            const SliverToBoxAdapter(child: PropertyRoomSkeleton()),
          if (rooms == null && roomValue.hasError)
            SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(roomsProvider),
                  child: const Text('Retry loading rooms'),
                ),
              ),
            ),
          if (rooms != null && visible.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No rooms match your search or filters.'),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: RoomDashboardCard(
                key: ValueKey(visible[index].id),
                room: visible[index],
              ),
            ),
          ),
          if (ref.read(roomsProvider.notifier).hasMore && rooms != null)
            SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => ref.read(roomsProvider.notifier).loadMore(),
                  child: const Text('Load more rooms'),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, {VoidCallback? onTap}) =>
      Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    color: PgTheme.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, maxLines: 2),
              ],
            ),
          ),
        ),
      );
  Widget _listingTab(AsyncValue<List<Room>> rooms) => PgAsync(
    value: rooms,
    data: (items) {
      final published = items.where((room) => room.isPublished).toList();
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Published rooms',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final room in published) RoomDashboardCard(room: room),
          if (published.isEmpty && !ref.read(roomsProvider.notifier).hasMore)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No rooms are published.'),
            ),
          if (ref.read(roomsProvider.notifier).hasMore)
            Center(
              child: TextButton(
                onPressed: () => ref.read(roomsProvider.notifier).loadMore(),
                child: const Text('Load more rooms'),
              ),
            ),
        ],
      );
    },
  );
  Widget _complaintTab(String id) => Consumer(
    builder: (context, ref, _) => PgAsync(
      value: ref.watch(_complaintsForProperty(id)),
      data: (items) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (items.isEmpty) const Text('No complaints for this property.'),
          for (final item in items)
            Card(
              child: ListTile(
                title: Text('${item['description'] ?? 'Complaint'}'),
                subtitle: Text('${item['status'] ?? ''}'),
              ),
            ),
        ],
      ),
    ),
  );
}

class RoomDashboardCard extends ConsumerStatefulWidget {
  const RoomDashboardCard({super.key, required this.room});
  final Room room;
  @override
  ConsumerState<RoomDashboardCard> createState() => _RoomDashboardCardState();
}

class _RoomDashboardCardState extends ConsumerState<RoomDashboardCard> {
  bool open = false, busy = false;
  Future<void> action(String path, {bool delete = false}) async {
    if (delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Delete room?'),
          content: const Text(
            'This archives the room. Active tenants must be moved first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => busy = true);
    try {
      if (delete) {
        await ref.read(operationsViewModelProvider).delete(path);
      } else {
        await ref.read(operationsViewModelProvider).update(path, {});
      }
      ref.invalidate(roomsProvider);
      ref.invalidate(roomProvider(widget.room.id));
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          open = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final vacant = room.beds.where((b) => b.status == 'AVAILABLE').length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 165,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => context.push('/rooms/${room.id}/edit'),
                      child: const Text('Edit Room'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () =>
                                action('/rooms/${room.id}/toggle-disable-rent'),
                      child: Text(
                        room.isDisabledForRent
                            ? 'Enable for Rent'
                            : 'Disable for Rent',
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => action('/rooms/${room.id}/toggle-publish'),
                      child: Text(room.isPublished ? 'Unpublish' : 'Publish'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => action('/rooms/${room.id}', delete: true),
                      child: const Text(
                        'Delete Room',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            transform: Matrix4.translationValues(open ? -165 : 0, 0, 0),
            child: GestureDetector(
              onHorizontalDragEnd: (details) =>
                  setState(() => open = (details.primaryVelocity ?? 0) < 0),
              child: Material(
                color: Colors.white,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => showRoomDetailsSheet(context, room.id),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: room.images.isEmpty
                                    ? const ColoredBox(
                                        color: Color(0xffe9edff),
                                        child: Icon(Icons.bed_outlined),
                                      )
                                    : Image.network(
                                        room.images.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.bed_outlined),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.roomNumber,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${rupees(room.rentAmount)}/bed · ${room.unitType} · ${room.sharingType.replaceAll('_', ' ')}',
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.more_vert, color: PgTheme.blue),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          for (final bed in room.beds.take(5))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => showRoomDetailsSheet(
                                  context,
                                  room.id,
                                  selectedBedId: bed.id,
                                ),
                                child: Container(
                                  width: 34,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: bed.status == 'AVAILABLE'
                                        ? const Color(0xffe8f7e8)
                                        : const Color(0xffffe9e9),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(
                                    Icons.bed,
                                    size: 20,
                                    color: bed.status == 'AVAILABLE'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton.filled(
                            tooltip: 'Add tenant',
                            onPressed: () =>
                                context.push('/tenants/new?roomId=${room.id}'),
                            icon: const Icon(Icons.person_add_alt_1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: const Color(0xfff8f9fd),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Chip(
                            label: Text(
                              '$vacant bed${vacant == 1 ? '' : 's'} vacant',
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (room.isDisabledForRent)
                            const Chip(label: Text('Rent disabled')),
                          const Spacer(),
                          InkWell(
                            onTap: () => showRoomDetailsSheet(context, room.id),
                            child: const Icon(Icons.chevron_right),
                          ),
                        ],
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
  }
}

void showRoomDetailsSheet(
  BuildContext context,
  String roomId, {
  String? selectedBedId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Consumer(
          builder: (context, ref, _) {
            final value = ref.watch(roomProvider(roomId));
            return PgAsync(
              value: value,
              data: (room) => StatefulBuilder(
                builder: (context, setSheetState) => ListView(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 86,
                            height: 86,
                            child: room.images.isEmpty
                                ? const Icon(Icons.bed, size: 50)
                                : Image.network(
                                    room.images.first,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.roomNumber,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                Text(
                                  '${room.floor} Floor · ${room.unitType} · ${room.sharingType.replaceAll('_', ' ')}',
                                ),
                                Text(
                                  '${room.beds.where((b) => b.status == 'AVAILABLE').length} bed vacant',
                                  style: const TextStyle(color: PgTheme.blue),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const ListTile(title: Text('Occupancy Status')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        children: [
                          for (final bed in room.beds)
                            ActionChip(
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bed,
                                    color: bed.status == 'AVAILABLE'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  Text(bed.bedNumber),
                                ],
                              ),
                              backgroundColor: bed.status == 'AVAILABLE'
                                  ? const Color(0xffe8f7e8)
                                  : const Color(0xffffe9e9),
                              onPressed: () =>
                                  setSheetState(() => selectedBedId = bed.id),
                            ),
                        ],
                      ),
                    ),
                    if (selectedBedId != null)
                      Builder(
                        builder: (context) {
                          final bed = room.beds
                              .where((b) => b.id == selectedBedId)
                              .firstOrNull;
                          if (bed == null) return const SizedBox();
                          final tenant = bed.residents.firstOrNull;
                          return Card(
                            margin: const EdgeInsets.all(16),
                            child: ListTile(
                              title: Text(
                                'Bed ${bed.bedNumber} · ${bed.status}',
                              ),
                              subtitle: Text(
                                tenant == null
                                    ? 'No tenant assigned'
                                    : '${tenant.firstName} ${tenant.lastName ?? ''}',
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  context.push(
                                    tenant == null
                                        ? '/tenants/new?roomId=${room.id}&bedId=${bed.id}'
                                        : '/tenants/${tenant.id}',
                                  );
                                },
                                child: Text(
                                  tenant == null ? 'Add Tenant' : 'View',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const Divider(),
                    ListTile(
                      title: const Text('Facilities'),
                      subtitle: Text(
                        room.amenities.isEmpty
                            ? 'No facilities added.'
                            : room.amenities.join(', '),
                      ),
                    ),
                    ListTile(
                      title: const Text('Remarks'),
                      subtitle: Text(
                        room.remarks?.isNotEmpty == true
                            ? room.remarks!
                            : 'No remarks added.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                context.push('/rooms/${room.id}/edit');
                              },
                              child: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                context.push('/tenants/new?roomId=${room.id}');
                              },
                              child: const Text('Add Tenant'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class PropertyRoomSkeleton extends StatefulWidget {
  const PropertyRoomSkeleton({super.key});
  @override
  State<PropertyRoomSkeleton> createState() => _PropertyRoomSkeletonState();
}

class _PropertyRoomSkeletonState extends State<PropertyRoomSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else if (!animation.isAnimating) {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment(-1 + animation.value * 2, 0),
          end: Alignment(animation.value * 2, 0),
          colors: const [
            Color(0xffeceef3),
            Color(0xfffafbfc),
            Color(0xffeceef3),
          ],
        ),
      ),
    );
    return Semantics(
      label: 'Loading rooms',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              block(60, 60),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  block(76, 18),
                                  const SizedBox(height: 12),
                                  block(170, 14),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              for (var n = 0; n < 4; n++) ...[
                                block(34, 40),
                                const SizedBox(width: 8),
                              ],
                              const Spacer(),
                              block(40, 40),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              block(110, 28),
                              const SizedBox(width: 8),
                              block(90, 28),
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
    );
  }
}
