import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

class RedesignedRoomFormScreen extends ConsumerStatefulWidget {
  const RedesignedRoomFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<RedesignedRoomFormScreen> createState() =>
      _RedesignedRoomFormState();
}

class _RedesignedRoomFormState extends ConsumerState<RedesignedRoomFormScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      rent = TextEditingController(),
      beds = TextEditingController(text: '1');
  final description = TextEditingController(),
      remarks = TextEditingController();
  String unit = 'Room', floor = '0', sharing = 'SINGLE', gender = 'UNISEX';
  final facilities = <String>{};
  bool busy = false, loaded = false, availableForRent = true;
  static const facilityChoices = [
    'WiFi',
    'AC',
    'Attached Bathroom',
    'Balcony',
    'TV',
    'Furniture',
    'Parking',
    'Hot Water',
    'Power Backup',
  ];
  static const sharingChoices = [
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
  ];

  @override
  void dispose() {
    for (final c in [name, rent, beds, description, remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  void populate(Room room) {
    if (loaded) return;
    loaded = true;
    name.text = room.roomNumber;
    rent.text = (room.rentAmount / 100).toStringAsFixed(0);
    beds.text = '${room.beds.length}';
    description.text = room.description ?? '';
    remarks.text = room.remarks ?? '';
    unit = room.unitType;
    floor = room.floor;
    sharing = room.sharingType;
    gender = room.gender;
    availableForRent = !room.isDisabledForRent;
    facilities.addAll(room.amenities);
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final propertyId = ref.read(selectedPropertyProvider);
    if (propertyId == null && widget.id == null) {
      showError(context, 'Select a property first');
      return;
    }
    setState(() => busy = true);
    try {
      final body = <String, dynamic>{
        'roomNumber': name.text.trim(),
        'unitType': unit,
        'floor': floor,
        'sharingType': sharing,
        'rentAmount': parseRupees(rent.text),
        'gender': gender,
        'amenities': facilities.toList(),
        'description': description.text.trim(),
        'remarks': remarks.text.trim(),
        'isDisabledForRent': !availableForRent,
        if (widget.id == null) 'initialBedCount': int.parse(beds.text),
      };
      if (widget.id == null) {
        await ref
            .read(operationsViewModelProvider)
            .createRoom(propertyId!, body);
      } else {
        await ref
            .read(operationsViewModelProvider)
            .update('/rooms/${widget.id}', body);
        ref.invalidate(roomProvider(widget.id!));
      }
      ref.invalidate(roomsProvider);
      ref.invalidate(propertiesProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.id == null
        ? null
        : ref.watch(roomProvider(widget.id!));
    final selected = ref.watch(selectedPropertyProvider);
    final propertyName = ref
        .watch(propertiesProvider)
        .asData
        ?.value
        .where((p) => p.id == selected)
        .firstOrNull
        ?.name;
    if (existing?.asData != null) populate(existing!.asData!.value);
    if (existing != null && existing.isLoading && !loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Room')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (existing != null && existing.hasError && !loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Room')),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(roomProvider(widget.id!)),
            child: const Text('Retry loading room'),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffedf1ff),
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.id == null ? 'Add Room' : 'Edit Room'),
            if (propertyName != null)
              Text(
                propertyName,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
          ],
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Room Renting Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xff3156f5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            PgField('Room Name', controller: name, validator: requiredText),
            _dropdown('Unit Type', unit, const [
              'Room',
              '1RK',
              '1BHK',
              '2BHK',
              '3BHK',
              '4BHK',
              '5BHK',
            ], (v) => setState(() => unit = v)),
            _dropdown(
              'Floor Selection',
              floor,
              ['Basement', '0', for (var i = 1; i <= 15; i++) '$i'],
              (v) => setState(() => floor = v),
              label: (v) => v == '0'
                  ? 'Ground Floor'
                  : v == 'Basement'
                  ? v
                  : '$v${_suffix(int.parse(v))} Floor',
            ),
            _dropdown(
              'Sharing Type',
              sharing,
              sharingChoices,
              (v) => setState(() => sharing = v),
              label: (v) => v.replaceAll('_', ' '),
            ),
            PgField(
              'Monthly Rent per Bed (₹)',
              controller: rent,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (tryParseRupees(v) ?? 0) > 0 ? null : 'Enter a positive rent',
            ),
            if (widget.id == null)
              PgField(
                'Number of Beds',
                controller: beds,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n != null && n >= 1 && n <= 20
                      ? null
                      : 'Enter 1–20 beds';
                },
              ),
            const SizedBox(height: 12),
            Text(
              'Room Facilities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final f in facilityChoices)
                  FilterChip(
                    label: Text(f),
                    selected: facilities.contains(f),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        facilities.add(f);
                      } else {
                        facilities.remove(f);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _dropdown(
              'Gender Preference',
              gender,
              const ['UNISEX', 'MALE', 'FEMALE'],
              (v) => setState(() => gender = v),
              label: (v) =>
                  v == 'UNISEX' ? 'Any' : v[0] + v.substring(1).toLowerCase(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available to Rent'),
              value: availableForRent,
              onChanged: (value) => setState(() => availableForRent = value),
            ),
            PgField('Description', controller: description, maxLines: 2),
            PgField(
              'Other Details / Remarks',
              controller: remarks,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SafeArea(
              child: FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  busy
                      ? 'Saving…'
                      : widget.id == null
                      ? 'Add Room'
                      : 'Save Room',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> onChanged, {
    String Function(String)? label,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : options.first,
      decoration: InputDecoration(labelText: title),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(label?.call(option) ?? option),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    ),
  );
  String _suffix(int n) => n % 100 >= 11 && n % 100 <= 13
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
}
