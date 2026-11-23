import 'dart:async';

import '../../money/money_data.dart';
import 'tenant_skeleton.dart';
import 'tenant_actions.dart' show allocationRoomsProvider;

import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/di/providers.dart';
import '../../../core/design_system/theme.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';

class AddTenantScreen extends ConsumerStatefulWidget {
  const AddTenantScreen({super.key, this.initialRoomId, this.initialBedId});
  final String? initialRoomId, initialBedId;
  @override
  ConsumerState<AddTenantScreen> createState() => _AddTenantState();
}

class _OpeningEntry {
  _OpeningEntry({
    required this.amount,
    required this.dueDate,
    this.collectedAmount = 0,
    this.dueEndDate,
    this.description = '',
    this.type = 'OTHER',
    this.collectionMode = 'OTHER',
    this.attachments = const [],
  });
  final int amount, collectedAmount;
  final DateTime dueDate;
  final DateTime? dueEndDate;
  final String description;
  final String type, collectionMode;
  final List<XFile> attachments;
}

class _AddTenantState extends ConsumerState<AddTenantScreen>
    with SingleTickerProviderStateMixin {
  late final tabs = TabController(length: 3, vsync: this);
  final sections = List.generate(3, (_) => GlobalKey());
  static const frequencies = {
    '1': 'Monthly',
    '3': 'Quarterly',
    '6': 'Half-yearly',
    '10': 'Every 10 months',
    '11': 'Every 11 months',
    '12': 'Yearly',
  };
  String frequency = '1';
  bool includeOpeningRent = true;

  void showSection(int index) {
    tabs.animateTo(index);
    final section = sections[index].currentContext;
    if (section != null) {
      Scrollable.ensureVisible(
        section,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  final first = TextEditingController(),
      last = TextEditingController(),
      phone = TextEditingController(),
      alternate = TextEditingController(),
      parentName = TextEditingController(),
      parentPhone = TextEditingController();
  final onboardingKey = const Uuid().v4();
  final rent = TextEditingController(),
      deposit = TextEditingController(text: '0'),
      dueDay = TextEditingController(text: '1');
  final lockMonths = TextEditingController(text: '0'),
      noticeDays = TextEditingController(text: '0'),
      agreementMonths = TextEditingController(text: '12'),
      remarks = TextEditingController();
  final entries = <_OpeningEntry>[];
  String? roomId, bedId, propertyId, allocationLabel;
  String stayType = 'LONG_TERM', tenantType = 'OTHER';
  bool whatsapp = true, busy = false;
  DateTime moveIn = DateUtils.dateOnly(DateTime.now());
  DateTime? moveOut;
  @override
  void initState() {
    super.initState();
    propertyId = ref.read(selectedPropertyProvider);
    roomId = widget.initialRoomId;
    bedId = widget.initialBedId;
  }

  @override
  void dispose() {
    tabs.dispose();
    for (final c in [
      first,
      last,
      phone,
      alternate,
      parentName,
      parentPhone,
      rent,
      deposit,
      dueDay,
      lockMonths,
      noticeDays,
      agreementMonths,
      remarks,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String date(DateTime? value) => value == null
      ? 'Select date'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String iso(DateTime value) => value.toIso8601String().substring(0, 10);
  Future<DateTime?> pickDate(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  Future<void> selectRoom() async {
    final property = propertyId;
    if (property == null) {
      showError(context, 'Select a property first');
      return;
    }
    var search = '';
    Timer? debounce;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: .75,
            child: Column(
              children: [
                const ListTile(title: Text('Select a room and bed')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search rooms',
                    ),
                    onChanged: (value) {
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 300), () {
                        if (sheetContext.mounted) {
                          setSheet(() => search = value.trim());
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, sheetRef, _) => PgAsync(
                      value: sheetRef.watch(
                        allocationRoomsProvider((property, search)),
                      ),
                      placeholder: const TenantSkeleton(
                        TenantPlaceholder.fields,
                      ),
                      retry: () => sheetRef.invalidate(
                        allocationRoomsProvider((property, search)),
                      ),
                      data: (rooms) {
                        if (rooms.isEmpty) {
                          return const Center(
                            child: Text('No rooms match your search.'),
                          );
                        }
                        return ListView(
                          children: [
                            for (final room in rooms)
                              ExpansionTile(
                                title: Text('Room ${room.roomNumber}'),
                                subtitle: Text(
                                  '${room.beds.where((bed) => bed.status == 'AVAILABLE' && !bed.isDisabledForRent && !room.isDisabledForRent).length} available beds',
                                ),
                                children: [
                                  for (final bed in room.beds)
                                    _bedTile(sheetContext, room, bed),
                                  if (room.beds.isEmpty &&
                                      !room.isDisabledForRent)
                                    ListTile(
                                      title: const Text(
                                        'Select room without a bed',
                                      ),
                                      onTap: () {
                                        setState(() {
                                          roomId = room.id;
                                          bedId = null;
                                          allocationLabel =
                                              'Room ${room.roomNumber}';
                                        });
                                        Navigator.pop(sheetContext);
                                      },
                                    ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    debounce?.cancel();
  }

  Widget _bedTile(BuildContext sheetContext, Room room, Bed bed) {
    final vacant =
        bed.status == 'AVAILABLE' &&
        !bed.isDisabledForRent &&
        !room.isDisabledForRent;
    final occupied = bed.status == 'OCCUPIED';
    return ListTile(
      enabled: vacant,
      leading: Icon(
        Icons.bed_outlined,
        color: vacant
            ? PgTheme.occupiedBedFg(context)
            : occupied
            ? PgTheme.availableBedFg(context)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text('Bed ${bed.bedNumber}'),
      subtitle: Text(
        vacant
            ? 'Vacant'
            : bed.status == 'AVAILABLE'
            ? 'Unavailable'
            : bed.status.toLowerCase().replaceAll('_', ' '),
      ),
      onTap: !vacant
          ? null
          : () {
              setState(() {
                roomId = room.id;
                bedId = bed.id;
                allocationLabel =
                    'Room ${room.roomNumber} · Bed ${bed.bedNumber}';
              });
              Navigator.pop(sheetContext);
            },
    );
  }

  Future<void> editOpening({
    _OpeningEntry? existing,
    bool collection = false,
  }) async {
    final amount = TextEditingController(
      text: existing == null
          ? ''
          : ((collection ? existing.collectedAmount : existing.amount) / 100)
                .toStringAsFixed(2),
    );
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    var type = existing?.type ?? 'OTHER';
    var mode = existing?.collectionMode ?? 'OTHER';
    var due = existing?.dueDate ?? DateTime.now();
    DateTime? end = existing?.dueEndDate;
    var attachments = <XFile>[...?existing?.attachments];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection ? 'Edit Collection' : 'Edit Due',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (collection)
                  _dropdown('Collection mode', mode, const {
                    'CASH': 'Cash',
                    'UPI': 'UPI',
                    'BANK_TRANSFER': 'Bank transfer',
                    'CHEQUE': 'Cheque',
                    'OTHER': 'Other',
                  }, (value) => setSheet(() => mode = value))
                else
                  _dropdown('Due type', type, const {
                    'RENT': 'Rent',
                    'ELECTRICITY': 'Electricity',
                    'WATER': 'Water',
                    'MAINTENANCE': 'Maintenance',
                    'LATE_FEE': 'Late fee',
                    'OTHER': 'Other',
                  }, (value) => setSheet(() => type = value)),
                PgField(
                  collection ? 'Collection Amount (₹)' : 'Due Amount (₹)',
                  controller: amount,
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text(collection ? 'Collection Date' : 'Due Date'),
                  subtitle: Text(date(due)),
                  onTap: () async {
                    final next = await pickDate(due);
                    if (next != null) setSheet(() => due = next);
                  },
                ),
                if (!collection)
                  ListTile(
                    title: const Text('Due End Date'),
                    subtitle: Text(date(end)),
                    onTap: () async {
                      final next = await pickDate(end);
                      if (next != null) setSheet(() => end = next);
                    },
                  ),
                if (!collection)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final files = await ImagePicker().pickMultiImage(
                        imageQuality: 85,
                        maxWidth: 2400,
                      );
                      if (files.isNotEmpty) {
                        setSheet(() => attachments = files.take(5).toList());
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      attachments.isEmpty
                          ? 'Upload Attachments'
                          : '${attachments.length} attachment(s) selected',
                    ),
                  ),
                PgField('Description', controller: description, maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final value = tryParseRupees(amount.text);
                      if (value == null || value <= 0) {
                        showError(sheetContext, 'Enter a positive amount');
                        return;
                      }
                      if (!collection && end != null && end!.isBefore(due)) {
                        showError(
                          sheetContext,
                          'Due end date must be on or after the due date',
                        );
                        return;
                      }
                      final next = _OpeningEntry(
                        type: type,
                        collectionMode: mode,
                        amount: collection ? 0 : value,
                        collectedAmount: collection ? value : 0,
                        dueDate: due,
                        dueEndDate: end,
                        attachments: attachments,
                        description: description.text.trim(),
                      );
                      setState(() {
                        if (existing != null) {
                          entries[entries.indexOf(existing)] = next;
                        } else {
                          entries.add(next);
                        }
                      });
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    amount.dispose();
    description.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    final property = propertyId;
    if (property == null ||
        ref.read(propertiesProvider).value?.any((p) => p.id == property) !=
            true) {
      showSection(0);
      showError(context, 'Select a property');
      return;
    }
    if (first.text.trim().isEmpty ||
        mobileValidator(phone.text.trim()) != null) {
      showSection(0);
      showError(context, 'Enter a name and valid phone number');
      return;
    }
    if (parentPhone.text.trim().isNotEmpty &&
        mobileValidator(parentPhone.text.trim()) != null) {
      showSection(0);
      showError(context, 'Enter a valid parent phone number');
      return;
    }
    if (alternate.text.trim().isNotEmpty &&
        mobileValidator(alternate.text.trim()) != null) {
      showSection(0);
      showError(context, 'Enter a valid alternate phone number');
      return;
    }
    if ((tryParseRupees(rent.text) ?? 0) <= 0 ||
        (tryParseRupees(deposit.text) ?? -1) < 0) {
      showSection(1);
      showError(context, 'Enter a valid rent and deposit');
      return;
    }
    if (parseRupees(rent.text) * int.parse(frequency) > 2147483647) {
      showSection(1);
      showError(context, 'The rent for one billing period is too large');
      return;
    }
    final day = int.tryParse(dueDay.text),
        lock = int.tryParse(lockMonths.text),
        notice = int.tryParse(noticeDays.text),
        agreement = int.tryParse(agreementMonths.text);
    if (day == null ||
        day < 1 ||
        day > 28 ||
        lock == null ||
        lock < 0 ||
        notice == null ||
        notice < 0 ||
        notice > 365 ||
        agreement == null ||
        agreement < 1 ||
        agreement > 120 ||
        (moveOut != null && moveOut!.isBefore(moveIn))) {
      showSection(1);
      showError(context, 'Check the stay dates and periods');
      return;
    }
    setState(() => busy = true);
    try {
      final repository = ref.read(operationsViewModelProvider);
      final balances = await Future.wait(
        entries.map(
          (e) async => {
            'type': e.type,
            'amount': e.amount,
            'collectedAmount': e.collectedAmount,
            if (e.collectedAmount > 0) 'collectionDate': iso(e.dueDate),
            'dueDate': iso(e.dueDate),
            if (e.dueEndDate != null) 'dueEndDate': iso(e.dueEndDate!),
            'description': e.description,
            'collectionMode': e.collectionMode,
            'attachmentUrls': await Future.wait(
              e.attachments.map(
                (file) => repository.upload(
                  filePath: file.path,
                  filename: file.name,
                  purpose: 'tenant-document',
                ),
              ),
            ),
          },
        ),
      );
      DateTime? lockEnd;
      if (lock > 0) {
        lockEnd = DateTime(moveIn.year, moveIn.month + lock, moveIn.day);
      }
      await repository.createResident({
        'propertyId': property,
        'onboardingKey': onboardingKey,
        if (parentName.text.trim().isNotEmpty)
          'parentName': parentName.text.trim(),
        if (parentPhone.text.trim().isNotEmpty)
          'parentPhone': parentPhone.text.trim(),
        'firstName': first.text.trim(),
        'lastName': last.text.trim(),
        'mobile': phone.text.trim(),
        if (alternate.text.trim().isNotEmpty)
          'alternatePhone': alternate.text.trim(),
        'sendWhatsappReminder': whatsapp,
        if (roomId != null) 'roomId': roomId,
        if (bedId != null) 'bedId': bedId,
        'stayType': stayType,
        'tenantType': tenantType,
        'profession': tenantType == 'STUDENT'
            ? 'STUDENT'
            : tenantType == 'PROFESSIONAL'
            ? 'WORKING_PROFESSIONAL'
            : 'OTHER',
        'joiningDate': iso(moveIn),
        'moveInDate': iso(moveIn),
        if (moveOut != null) 'expectedVacatingDate': iso(moveOut!),
        if (lockEnd != null) 'lockInEndDate': iso(lockEnd),
        'noticePeriodDays': notice,
        'agreementPeriodMonths': agreement,
        'monthlyRent': parseRupees(rent.text),
        'rentalFrequencyMonths': int.parse(frequency),
        'initialRent': includeOpeningRent ? 'CREATE' : 'SKIP',
        'securityDeposit': parseRupees(deposit.text),
        'rentDueDay': day,
        'notes': remarks.text.trim(),
        'openingBalances': balances,
      });
      ref.invalidate(residentsProvider);
      ref.invalidate(roomsProvider);
      refreshMoney(ref);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PgTheme.subtleHeaderBg(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Add Tenant'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: tabs,
              onTap: showSection,
              tabs: const [
                Tab(
                  child: Text('Tenant\nDetails', textAlign: TextAlign.center),
                ),
                Tab(child: Text('Stay\nDetails', textAlign: TextAlign.center)),
                Tab(
                  child: Text('Payment\nDetails', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AbsorbPointer(
              absorbing: busy,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      key: sections[0],
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Tenant details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                PgField('Name', controller: first),
                                PgField('Last Name', controller: last),
                                PgField(
                                  'Phone Number',
                                  controller: phone,
                                  keyboardType: TextInputType.phone,
                                ),
                                PgField(
                                  'Alternate Phone Number',
                                  controller: alternate,
                                  keyboardType: TextInputType.phone,
                                ),
                                PgField('Parent name', controller: parentName),
                                PgField(
                                  'Parent phone',
                                  controller: parentPhone,
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SwitchListTile(
                          value: whatsapp,
                          onChanged: (v) => setState(() => whatsapp = v),
                          title: const Text('Send WhatsApp Reminder'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (properties.isLoading)
                          const TenantSkeleton(TenantPlaceholder.fields),
                        if (properties.hasError)
                          TextButton(
                            onPressed: () => ref.invalidate(propertiesProvider),
                            child: const Text('Retry loading properties'),
                          ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (properties.asData != null)
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        properties.asData!.value.any(
                                          (p) => p.id == propertyId,
                                        )
                                        ? propertyId
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Property',
                                    ),
                                    items: [
                                      for (final p in properties.asData!.value)
                                        DropdownMenuItem(
                                          value: p.id,
                                          child: Text(p.name),
                                        ),
                                    ],
                                    onChanged: (id) {
                                      setState(() {
                                        propertyId = id;
                                        allocationLabel = null;
                                        roomId = null;
                                        bedId = null;
                                      });
                                    },
                                  ),
                                const SizedBox(height: 12),
                                ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  title: const Text('Room / Bed'),
                                  subtitle: Text(
                                    allocationLabel ??
                                        (roomId == null
                                            ? 'Select a room and bed'
                                            : 'Room selected'),
                                  ),
                                  trailing: const Icon(
                                    Icons.keyboard_arrow_down,
                                  ),
                                  onTap: selectRoom,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      key: sections[1],
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Stay details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _dropdown('Stay Type', stayType, const {
                                  'LONG_TERM': 'Long-Term',
                                  'SHORT_TERM': 'Short-Term',
                                }, (v) => setState(() => stayType = v)),
                                ListTile(
                                  title: const Text('Move-in Date'),
                                  subtitle: Text(date(moveIn)),
                                  trailing: const Icon(Icons.calendar_month),
                                  onTap: () async {
                                    final d = await pickDate(moveIn);
                                    if (d != null && mounted) {
                                      setState(() => moveIn = d);
                                    }
                                  },
                                ),
                                ListTile(
                                  title: const Text('Move-out Date'),
                                  subtitle: Text(date(moveOut)),
                                  trailing: const Icon(Icons.calendar_month),
                                  onTap: () async {
                                    final d = await pickDate(moveOut);
                                    if (d != null && mounted) {
                                      setState(() => moveOut = d);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                PgField(
                                  'Lock-in Period (months)',
                                  controller: lockMonths,
                                  keyboardType: TextInputType.number,
                                ),
                                PgField(
                                  'Notice Period (days)',
                                  controller: noticeDays,
                                  keyboardType: TextInputType.number,
                                ),
                                PgField(
                                  'Agreement Period (months)',
                                  controller: agreementMonths,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                PgField(
                                  'Rent Due Date (1–28)',
                                  controller: dueDay,
                                  keyboardType: TextInputType.number,
                                ),
                                _dropdown(
                                  'Rental frequency',
                                  frequency,
                                  frequencies,
                                  (value) => setState(() => frequency = value),
                                ),
                                PgField(
                                  'Fixed rent per month (₹)',
                                  controller: rent,
                                  keyboardType: TextInputType.number,
                                ),
                                PgField(
                                  'Security Deposit (₹)',
                                  controller: deposit,
                                  keyboardType: TextInputType.number,
                                ),
                                _dropdown('Tenant Type', tenantType, const {
                                  'STUDENT': 'Student',
                                  'PROFESSIONAL': 'Professional',
                                  'BACHELOR': 'Bachelor',
                                  'FAMILY': 'Family',
                                  'COUPLE': 'Couple',
                                  'STAFF': 'Staff',
                                  'OTHER': 'Others',
                                }, (v) => setState(() => tenantType = v)),
                                PgField(
                                  'Remarks',
                                  controller: remarks,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      key: sections[2],
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Payment details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          'Opening balance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add existing dues and collections for this tenant.',
                        ),
                        const SizedBox(height: 16),
                        ListenableBuilder(
                          listenable: Listenable.merge([rent, deposit, dueDay]),
                          builder: (context, _) {
                            final rentAmount =
                                (tryParseRupees(rent.text) ?? 0) *
                                int.parse(frequency);
                            final depositAmount =
                                tryParseRupees(deposit.text) ?? 0;
                            final billingDay = (int.tryParse(dueDay.text) ?? 1)
                                .clamp(1, 28);
                            final firstRentDue = DateTime(
                              moveIn.year,
                              moveIn.month,
                              billingDay > moveIn.day ? billingDay : moveIn.day,
                            );
                            return Column(
                              children: [
                                if (rentAmount > 0)
                                  _automaticDue(
                                    'Opening rent',
                                    rentAmount,
                                    firstRentDue,
                                    includeOpeningRent
                                        ? () => setState(
                                            () => includeOpeningRent = false,
                                          )
                                        : null,
                                    restore: includeOpeningRent
                                        ? null
                                        : () => setState(
                                            () => includeOpeningRent = true,
                                          ),
                                  ),
                                if (depositAmount > 0)
                                  _automaticDue(
                                    'Security deposit',
                                    depositAmount,
                                    moveIn,
                                    () => deposit.text = '0',
                                  ),
                              ],
                            );
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: entries.length >= 20
                                    ? null
                                    : () => editOpening(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Due'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: entries.length >= 20
                                    ? null
                                    : () => editOpening(collection: true),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Collection'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final e in entries)
                          Dismissible(
                            key: ObjectKey(e),
                            direction: DismissDirection.startToEnd,
                            background: const ColoredBox(
                              color: Colors.red,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onDismissed: (_) =>
                                setState(() => entries.remove(e)),
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  e.amount > 0
                                      ? 'Due · ${rupees(e.amount)}'
                                      : 'Collection · ${rupees(e.collectedAmount)}',
                                ),
                                subtitle: Text(
                                  '${date(e.dueDate)}${e.description.isEmpty ? '' : ' · ${e.description}'}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Payment entry actions',
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      editOpening(
                                        existing: e,
                                        collection: e.amount == 0,
                                      );
                                    } else {
                                      setState(() => entries.remove(e));
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                                onTap: () => editOpening(
                                  existing: e,
                                  collection: e.amount == 0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Saving…' : 'Add Tenant'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _automaticDue(
    String label,
    int amount,
    DateTime dueAt,
    VoidCallback? remove, {
    VoidCallback? restore,
  }) => Card(
    child: ListTile(
      title: Text(label),
      subtitle: Text(
        restore == null
            ? '${rupees(amount)} · Due ${date(dueAt)}'
            : 'Skipped at check-in',
      ),
      onTap: restore ?? () => showSection(1),
      trailing: restore != null
          ? TextButton(onPressed: restore, child: const Text('Restore'))
          : PopupMenuButton<String>(
              tooltip: '$label actions',
              onSelected: (action) {
                if (action == 'edit') {
                  showSection(1);
                } else {
                  remove?.call();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
    ),
  );

  Widget _dropdown(
    String title,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: title),
      items: [
        for (final option in options.entries)
          DropdownMenuItem(value: option.key, child: Text(option.value)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}
