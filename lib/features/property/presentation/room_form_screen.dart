import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/design_system/theme.dart';
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
  final nameController = TextEditingController();
  final rentController = TextEditingController();
  final minDailyController = TextEditingController();
  final maxDailyController = TextEditingController();
  final areaController = TextEditingController();
  final remarksController = TextEditingController();

  String unitType = 'Room';
  String floor = '0';
  String sharingType = 'SINGLE';
  bool isAvailableForRent = true;
  bool isDetailsExpanded = true;
  bool isFacilitiesExpanded = true;
  final selectedFacilities = <String>{};

  bool busy = false;
  bool loaded = false;

  static const List<String> facilityChoices = [
    'AC',
    'Table',
    'TV',
    'Washroom',
    'Balcony',
    'Fridge',
    'Almirah',
    'Chair',
    'Food',
    'Microwave',
    'Geyser',
    'Laundry',
    'WiFi',
    'Parking',
    'Attached Bathroom',
    'Hot Water',
    'Power Backup',
  ];

  static const List<String> sharingChoices = [
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

  static const List<String> unitTypes = [
    'Room',
    '1RK',
    '1BHK',
    '2BHK',
    '3BHK',
    '4BHK',
    '5BHK',
  ];

  static const List<String> floorChoices = [
    'Basement',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
  ];

  @override
  void dispose() {
    nameController.dispose();
    rentController.dispose();
    minDailyController.dispose();
    maxDailyController.dispose();
    areaController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  void populate(Room room) {
    if (loaded) return;
    loaded = true;
    nameController.text = room.roomNumber;
    rentController.text = (room.rentAmount / 100).toStringAsFixed(0);
    if (room.dailyStayMinPaise != null) {
      minDailyController.text =
          (room.dailyStayMinPaise! / 100).toStringAsFixed(0);
    }
    if (room.dailyStayMaxPaise != null) {
      maxDailyController.text =
          (room.dailyStayMaxPaise! / 100).toStringAsFixed(0);
    }
    if (room.areaSqft != null) {
      areaController.text = room.areaSqft.toString();
    }
    remarksController.text = room.remarks ?? '';
    unitType = room.unitType;
    floor = room.floor;
    sharingType = room.sharingType;
    isAvailableForRent = !room.isDisabledForRent;
    selectedFacilities.addAll(room.amenities);
  }

  int _inferBedCount(String sharing) => switch (sharing) {
    'SINGLE' => 1,
    'DOUBLE' => 2,
    'TRIPLE' => 3,
    'FOUR_SHARING' => 4,
    'FIVE_SHARING' => 5,
    'SIX_SHARING' => 6,
    'SEVEN_SHARING' => 7,
    'EIGHT_SHARING' => 8,
    'NINE_SHARING' => 9,
    'TEN_SHARING' => 10,
    _ => 1,
  };

  String _formatFloor(String f) {
    if (f == '0' || f.toLowerCase() == 'ground' || f.toLowerCase() == 'ground floor') {
      return 'Ground Floor';
    }
    if (f == 'Basement') return 'Basement';
    final n = int.tryParse(f);
    if (n == null) return f;
    final suffix = switch (n % 10) {
      1 && != 11 => 'st',
      2 && != 12 => 'nd',
      3 && != 13 => 'rd',
      _ => 'th',
    };
    return '$n$suffix Floor';
  }

  String _formatSharing(String s) {
    return switch (s) {
      'SINGLE' => 'Single',
      'DOUBLE' => 'Double',
      'TRIPLE' => 'Triple',
      _ => s.replaceAll('_', ' '),
    };
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
      final rentPaise = parseRupees(rentController.text);
      final minDailyPaise = minDailyController.text.trim().isNotEmpty
          ? tryParseRupees(minDailyController.text)
          : null;
      final maxDailyPaise = maxDailyController.text.trim().isNotEmpty
          ? tryParseRupees(maxDailyController.text)
          : null;
      final area = int.tryParse(areaController.text.trim());

      final body = <String, dynamic>{
        'roomNumber': nameController.text.trim(),
        'unitType': unitType,
        'floor': floor,
        'sharingType': sharingType,
        'rentAmount': rentPaise,
        'amenities': selectedFacilities.toList(),
        'remarks': remarksController.text.trim().isNotEmpty
            ? remarksController.text.trim()
            : null,
        'isDisabledForRent': !isAvailableForRent,
        'dailyStayMinPaise': ?minDailyPaise,
        'dailyStayMaxPaise': ?maxDailyPaise,
        'areaSqft': ?area,
        if (widget.id == null) 'initialBedCount': _inferBedCount(sharingType),
      };

      if (widget.id == null) {
        final createdRoom = await ref
            .read(operationsViewModelProvider)
            .createRoom(propertyId!, body);
        ref.read(roomsProvider.notifier).addOptimisticRoom(createdRoom);
      } else {
        await ref
            .read(operationsViewModelProvider)
            .update('/rooms/${widget.id}', body);
        ref.invalidate(roomProvider(widget.id!));
        ref.read(roomsProvider.notifier).refresh();
      }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final headerBgColor = PgTheme.subtleHeaderBg(context);
    final borderColor = isDark ? const Color(0xff363b53) : const Color(0xffd1d5db);

    if (existing != null && existing.isLoading && !loaded) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: headerBgColor,
          foregroundColor: onSurfaceColor,
          title: Text(widget.id == null ? 'Add Room' : 'Edit Room'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (existing != null && existing.hasError && !loaded) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: headerBgColor,
          foregroundColor: onSurfaceColor,
          title: Text(widget.id == null ? 'Add Room' : 'Edit Room'),
        ),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(roomProvider(widget.id!)),
            child: const Text('Retry loading room'),
          ),
        ),
      );
    }

    final outlineDeco = InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xff1f2334) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PgTheme.royalBlue, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? PgTheme.darkCanvas : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: headerBgColor,
          foregroundColor: onSurfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.id == null ? 'Add Room' : 'Edit Room',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
              ),
              if (propertyName != null) ...[
                const SizedBox(height: 2),
                Text(
                  propertyName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white60 : const Color(0xff6b7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PgTheme.royalBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              onPressed: busy ? null : save,
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.id == null ? 'Add Room' : 'Save Room',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Accordion 1: Room Renting Details
            InkWell(
              onTap: () => setState(
                () => isDetailsExpanded = !isDetailsExpanded,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Room Renting Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: PgTheme.royalBlue,
                      ),
                    ),
                    Icon(
                      isDetailsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: PgTheme.royalBlue,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
            if (isDetailsExpanded) ...[
              const SizedBox(height: 12),
              // Row 1: Room Name & Unit Type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: nameController,
                      validator: requiredText,
                      decoration: outlineDeco.copyWith(
                        labelText: 'Room Name',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unitType,
                      decoration: outlineDeco.copyWith(
                        labelText: 'Unit Type',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: unitTypes
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => unitType = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Row 2: Floor Selection
              DropdownButtonFormField<String>(
                initialValue: floorChoices.contains(floor) ? floor : '0',
                decoration: outlineDeco.copyWith(
                  labelText: 'Floor',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: PgTheme.royalBlue),
                items: floorChoices
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(_formatFloor(f)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => floor = v);
                },
              ),
              const SizedBox(height: 14),
              // Row 3: Sharing Type & Rent
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: sharingType,
                      decoration: outlineDeco.copyWith(
                        labelText: 'Sharing Type',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: PgTheme.royalBlue,
                      ),
                      items: sharingChoices
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                _formatSharing(s),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => sharingType = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: rentController,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (tryParseRupees(v) ?? 0) > 0 ? null : 'Enter rent',
                      decoration: outlineDeco.copyWith(
                        labelText: 'Rent',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 6),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Daily Stay Charges?
              Text(
                'Daily Stay Charges?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minDailyController,
                      keyboardType: TextInputType.number,
                      decoration: outlineDeco.copyWith(
                        hintText: 'Minimum',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: maxDailyController,
                      keyboardType: TextInputType.number,
                      decoration: outlineDeco.copyWith(
                        hintText: 'Maximum',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Area(Sqft)
              TextFormField(
                controller: areaController,
                keyboardType: TextInputType.number,
                decoration: outlineDeco.copyWith(
                  hintText: 'Area(Sqft)',
                ),
              ),
              const SizedBox(height: 18),
              // Is this Room available to Rent
              Text(
                'Is this Room available to Rent',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceColor,
                ),
              ),
              const SizedBox(height: 6),
              RadioGroup<bool>(
                groupValue: isAvailableForRent,
                onChanged: (v) {
                  if (v != null) setState(() => isAvailableForRent = v);
                },
                child: Row(
                  children: [
                    const Radio<bool>(
                      value: true,
                      activeColor: PgTheme.royalBlue,
                    ),
                    InkWell(
                      onTap: () => setState(() => isAvailableForRent = true),
                      child: const Text('Yes', style: TextStyle(fontSize: 15)),
                    ),
                    const SizedBox(width: 48),
                    const Radio<bool>(
                      value: false,
                      activeColor: PgTheme.royalBlue,
                    ),
                    InkWell(
                      onTap: () => setState(() => isAvailableForRent = false),
                      child: const Text('No', style: TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Remarks
              TextFormField(
                controller: remarksController,
                decoration: outlineDeco.copyWith(
                  hintText: 'Remarks',
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(height: 24),

            // Accordion 2: Room Facilities
            InkWell(
              onTap: () => setState(
                () => isFacilitiesExpanded = !isFacilitiesExpanded,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Room Facilities',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: PgTheme.royalBlue,
                      ),
                    ),
                    Icon(
                      isFacilitiesExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: PgTheme.royalBlue,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
            if (isFacilitiesExpanded) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final facility in facilityChoices)
                    _FacilityPill(
                      label: facility,
                      selected: selectedFacilities.contains(facility),
                      onTap: () {
                        setState(() {
                          if (selectedFacilities.contains(facility)) {
                            selectedFacilities.remove(facility);
                          } else {
                            selectedFacilities.add(facility);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _FacilityPill extends StatelessWidget {
  const _FacilityPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBorder =
        isDark ? const Color(0xff3f4561) : const Color(0xffd1d5db);
    final unselectedBg =
        isDark ? const Color(0xff1a1d2c) : Colors.white;
    final selectedBg =
        isDark ? const Color(0xff1e3a8a) : const Color(0xffeff4ff);
    final selectedBorder = PgTheme.royalBlue;
    final textColor = selected
        ? PgTheme.royalBlue
        : (isDark ? Colors.white70 : const Color(0xff374151));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? selectedBorder : unselectedBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
