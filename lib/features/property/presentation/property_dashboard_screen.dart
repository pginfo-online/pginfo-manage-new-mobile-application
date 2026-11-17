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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? PgTheme.darkCard : PgTheme.blue,
          title: InkWell(
            onTap: () => context.push('/properties/select'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.apartment),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      property?.name ?? 'Select property',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : const Color(0xffb9c5fa),
            tabs: const [
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
                backgroundColor: PgTheme.blue,
                foregroundColor: Colors.white,
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
                  Center(
                    child: Text(
                      'No food service data is available for this property.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      color: PgTheme.blue,
      onRefresh: () async {
        await Future.wait([
          ref.read(roomsProvider.notifier).refresh(),
          ref.refresh(propertiesProvider.future),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Failed to load rooms',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.read(roomsProvider.notifier).refresh(),
                        child: const Text('Retry loading rooms'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (rooms != null && visible.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No rooms match your search or filters.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TextButton(
                    onPressed: () => ref.read(roomsProvider.notifier).loadMore(),
                    child: const Text('Load more rooms'),
                  ),
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
        color: PgTheme.cardBg(context),
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
                Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Published rooms',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final room in published)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RoomDashboardCard(room: room),
                ),
              if (published.isEmpty && !ref.read(roomsProvider.notifier).hasMore)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No rooms are published.')),
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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No complaints for this property.'),
                  ),
                ),
              for (final item in items)
                Card(
                  color: PgTheme.cardBg(context),
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
  bool open = false;
  bool busy = false;

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
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => busy = true);
    final isDisableRent = path.contains('toggle-disable-rent');
    final isPublish = path.contains('toggle-publish');

    // Optimistic UI updates - instant response for user
    if (delete) {
      ref.read(roomsProvider.notifier).removeOptimisticRoom(widget.room.id);
    } else if (isDisableRent) {
      ref
          .read(roomsProvider.notifier)
          .toggleDisableRentOptimistic(widget.room.id);
    } else if (isPublish) {
      ref.read(roomsProvider.notifier).togglePublishOptimistic(widget.room.id);
    }
    setState(() => open = false);

    try {
      if (delete) {
        await ref.read(operationsViewModelProvider).delete(path);
      } else {
        await ref.read(operationsViewModelProvider).update(path, {});
      }
      ref.invalidate(roomProvider(widget.room.id));
      ref.invalidate(propertiesProvider);
    } catch (error) {
      // Revert optimistic update on failure
      ref.read(roomsProvider.notifier).refresh();
      if (mounted) showError(context, error);
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final vacant = room.beds.where((b) => b.status == 'AVAILABLE').length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = PgTheme.cardBg(context);
    final secondaryBg = PgTheme.secondaryBg(context);
    final headerBg = PgTheme.subtleHeaderBg(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                color: isDark ? const Color(0xff161926) : const Color(0xfff3f4f8),
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
                          : () => action(
                                '/rooms/${room.id}/toggle-disable-rent',
                              ),
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
                color: cardBg,
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
                                    ? ColoredBox(
                                        color: headerBg,
                                        child: const Icon(
                                          Icons.bed_outlined,
                                          color: PgTheme.blue,
                                        ),
                                      )
                                    : Image.network(
                                        room.images.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => ColoredBox(
                                          color: headerBg,
                                          child: const Icon(
                                            Icons.bed_outlined,
                                            color: PgTheme.blue,
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
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xff4b5563),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: PgTheme.blue),
                              onPressed: () => setState(() => open = !open),
                            ),
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
                                        ? PgTheme.availableBedBg(context)
                                        : PgTheme.occupiedBedBg(context),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(
                                    Icons.bed,
                                    size: 20,
                                    color: bed.status == 'AVAILABLE'
                                        ? PgTheme.availableBedFg(context)
                                        : PgTheme.occupiedBedFg(context),
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
                      color: secondaryBg,
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
    backgroundColor: Theme.of(context).cardColor,
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 86,
                              height: 86,
                              child: room.images.isEmpty
                                  ? ColoredBox(
                                      color: PgTheme.subtleHeaderBg(context),
                                      child: const Icon(Icons.bed, size: 50, color: PgTheme.blue),
                                    )
                                  : Image.network(
                                      room.images.first,
                                      fit: BoxFit.cover,
                                    ),
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
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${room.floor} Floor · ${room.unitType} · ${room.sharingType.replaceAll('_', ' ')}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${room.beds.where((b) => b.status == 'AVAILABLE').length} bed vacant',
                                  style: const TextStyle(
                                    color: PgTheme.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                        ? PgTheme.availableBedFg(context)
                                        : PgTheme.occupiedBedFg(context),
                                  ),
                                  Text(bed.bedNumber),
                                ],
                              ),
                              backgroundColor: bed.status == 'AVAILABLE'
                                  ? PgTheme.availableBedBg(context)
                                  : PgTheme.occupiedBedBg(context),
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
    final baseColor = PgTheme.skeletonBase(context);
    final highlightColor = PgTheme.skeletonHighlight(context);

    Widget block(double width, double height, {double radius = 8}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + animation.value * 2, 0),
              end: Alignment(animation.value * 2, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: PgTheme.cardBg(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              block(60, 60, radius: 10),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  block(80, 20),
                                  const SizedBox(height: 10),
                                  block(170, 14),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              for (var n = 0; n < 4; n++) ...[
                                block(34, 40, radius: 6),
                                const SizedBox(width: 8),
                              ],
                              const Spacer(),
                              block(40, 40, radius: 20),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              block(110, 28, radius: 14),
                              const SizedBox(width: 8),
                              block(90, 28, radius: 14),
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
