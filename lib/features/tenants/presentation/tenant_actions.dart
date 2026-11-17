import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';
import 'tenant_skeleton.dart';

enum TenantAction { delete, room, property, parent, notice }

class TenantQuickActions extends ConsumerStatefulWidget {
  const TenantQuickActions({
    super.key,
    required this.person,
    required this.child,
  });

  final Resident person;
  final Widget child;

  @override
  ConsumerState<TenantQuickActions> createState() => _TenantQuickActionsState();
}

class _TenantQuickActionsState extends ConsumerState<TenantQuickActions> {
  bool open = false;
  double drag = 0;

  Future<void> run(TenantAction action) async {
    setState(() => open = false);
    final person = widget.person;
    if (action == TenantAction.parent) {
      final phone = person.parentPhone;
      if (phone == null || phone.isEmpty) {
        showError(context, 'No parent phone number on file');
        return;
      }
      if (!await launchUrl(Uri(scheme: 'tel', path: phone)) && mounted) {
        showError(context, 'Unable to open the dialer');
      }
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _TenantActionScreen(person, action)),
    );
    if (changed == true && mounted) {
      ref.invalidate(residentProvider(person.id));
      ref.invalidate(pagedListProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(
        activityProvider((entityType: 'Resident', entityId: person.id)),
      );
    }
  }

  static const actions = {
    TenantAction.delete: 'Delete Tenant',
    TenantAction.room: 'Change Room',
    TenantAction.property: 'Change Property',
    TenantAction.parent: 'Call Parent',
    TenantAction.notice: 'Give Notice',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragStart: (_) => drag = 0,
    onHorizontalDragUpdate: (details) => drag += details.delta.dx,
    onHorizontalDragEnd: (_) {
      if (drag.abs() > 24) setState(() => open = drag < 0);
    },
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * .46;
            final duration = MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180);
            return ClipRect(
              child: Stack(
                children: [
                  if (open)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: Material(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            for (final entry in actions.entries)
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor:
                                      entry.key == TenantAction.delete
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                ),
                                onPressed: () => run(entry.key),
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  AnimatedSlide(
                    duration: duration,
                    offset: open ? const Offset(-.46, 0) : Offset.zero,
                    child: AbsorbPointer(absorbing: open, child: widget.child),
                  ),
                ],
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => open = !open),
            icon: Icon(open ? Icons.chevron_left : Icons.chevron_right),
            label: Text(open ? 'Close actions' : 'Tenant actions'),
          ),
        ),
      ],
    ),
  );
}

final allocationRoomsProvider = FutureProvider.autoDispose
    .family<List<Room>, (String, String)>(
      (ref, key) => ref
          .watch(repositoryProvider)
          .rooms(key.$1, search: key.$2, limit: 100),
    );

class _TenantActionScreen extends ConsumerStatefulWidget {
  const _TenantActionScreen(this.person, this.action);
  final Resident person;
  final TenantAction action;

  @override
  ConsumerState<_TenantActionScreen> createState() =>
      _TenantActionScreenState();
}

class _TenantActionScreenState extends ConsumerState<_TenantActionScreen> {
  late String? property = widget.action == TenantAction.property
      ? null
      : widget.person.propertyId;
  final reason = TextEditingController();
  String? room, bed;
  String search = '';
  DateTime date = DateTime.now();
  bool busy = false;

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    final action = widget.action;
    if (action == TenantAction.notice && reason.text.trim().isEmpty) {
      showError(context, 'Enter a notice reason');
      return;
    }
    if ((action == TenantAction.room || action == TenantAction.property) &&
        room == null) {
      showError(context, 'Select a room or bed');
      return;
    }
    setState(() => busy = true);
    final repo = ref.read(operationsViewModelProvider);
    final id = widget.person.id;
    try {
      switch (action) {
        case TenantAction.delete:
          await repo.create('/residents/bulk-move-out', {
            'residentIds': [id],
            'archive': true,
            'moveOutDate': DateTime.now().toIso8601String().substring(0, 10),
          });
        case TenantAction.notice:
          await repo.create('/residents/$id/notice', {
            'date': date.toIso8601String().substring(0, 10),
            'reason': reason.text.trim(),
          });
        case TenantAction.room:
        case TenantAction.property:
          await repo.create('/residents/$id/reallocate', {
            'propertyId': property,
            'roomId': room,
            'bedId': ?bed,
            'reason': action == TenantAction.property
                ? 'property_change'
                : 'room_change',
          });
        case TenantAction.parent:
          return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return Scaffold(
      appBar: AppBar(title: Text(_TenantQuickActionsState.actions[action]!)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: busy ? null : save,
          child: Text(
            busy
                ? 'Saving…'
                : action == TenantAction.delete
                ? 'Archive tenant'
                : 'Save',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(
              '${widget.person.firstName} ${widget.person.lastName ?? ''}'
                  .trim(),
            ),
          ),
          if (action == TenantAction.delete)
            const Text(
              'Archive this tenant and release their bed. Their financial history will be retained.',
            ),
          if (action == TenantAction.notice) ...[
            ListTile(
              title: const Text('Expected move-out date'),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(date),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateUtils.dateOnly(DateTime.now()),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) setState(() => date = picked);
              },
            ),
            PgField('Reason', controller: reason, maxLines: 4),
          ],
          if (action == TenantAction.property)
            PgAsync(
              value: ref.watch(propertiesProvider),
              placeholder: const TenantSkeleton(TenantPlaceholder.fields),
              retry: () => ref.invalidate(propertiesProvider),
              data: (properties) => DropdownButtonFormField<String>(
                initialValue: property,
                decoration: const InputDecoration(
                  labelText: 'Destination property',
                ),
                items: [
                  for (final item in properties)
                    if (item.id != widget.person.propertyId)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (value) => setState(() {
                  property = value;
                  room = bed = null;
                  search = '';
                }),
              ),
            ),
          if ((action == TenantAction.property ||
                  action == TenantAction.room) &&
              property != null) ...[
            TextFormField(
              key: ValueKey(property),
              decoration: const InputDecoration(
                labelText: 'Search rooms',
                prefixIcon: Icon(Icons.search),
              ),
              onFieldSubmitted: (value) =>
                  setState(() => search = value.trim()),
            ),
            PgAsync(
              value: ref.watch(allocationRoomsProvider((property!, search))),
              placeholder: const TenantSkeleton(TenantPlaceholder.fields),
              retry: () =>
                  ref.invalidate(allocationRoomsProvider((property!, search))),
              data: (rooms) {
                final available = rooms.where(
                  (item) =>
                      !item.isDisabledForRent &&
                      (item.beds.isEmpty ||
                          item.beds.any((bed) => bed.status == 'AVAILABLE')),
                );
                return Column(
                  children: [
                    if (available.isEmpty)
                      const ListTile(title: Text('No available rooms')),
                    for (final item in available)
                      if (item.beds.isEmpty)
                        ListTile(
                          title: Text('Room ${item.roomNumber}'),
                          selected: room == item.id,
                          onTap: () => setState(() {
                            room = item.id;
                            bed = null;
                          }),
                        )
                      else
                        ExpansionTile(
                          title: Text('Room ${item.roomNumber}'),
                          children: [
                            for (final option in item.beds.where(
                              (b) => b.status == 'AVAILABLE',
                            ))
                              ListTile(
                                title: Text('Bed ${option.bedNumber}'),
                                selected: bed == option.id,
                                onTap: () => setState(() {
                                  room = item.id;
                                  bed = option.id;
                                }),
                              ),
                          ],
                        ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
