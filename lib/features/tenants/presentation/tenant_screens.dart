import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';
import '../../all/presentation/action_screen.dart';
import 'tenant_actions.dart';
import 'tenant_skeleton.dart';

class TenantFormScreen extends ConsumerStatefulWidget {
  const TenantFormScreen({super.key});
  @override
  ConsumerState<TenantFormScreen> createState() => _TenantFormState();
}

class _TenantFormState extends ConsumerState<TenantFormScreen> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(),
      last = TextEditingController(),
      mobile = TextEditingController(),
      email = TextEditingController(),
      whatsapp = TextEditingController(),
      emergency = TextEditingController(),
      address = TextEditingController(),
      parentName = TextEditingController(),
      parentPhone = TextEditingController(),
      rent = TextEditingController(),
      deposit = TextEditingController(text: '0'),
      dueDay = TextEditingController(text: '1');
  String? roomId, bedId;
  String profession = 'OTHER';
  XFile? idProof, agreement;
  DateTime joining = DateTime.now();
  bool busy = false;
  @override
  void dispose() {
    for (final c in [
      first,
      last,
      mobile,
      email,
      whatsapp,
      emergency,
      address,
      parentName,
      parentPhone,
      rent,
      deposit,
      dueDay,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final property = ref.read(selectedPropertyProvider);
    if (property == null) {
      showError(context, 'Select a property first');
      return;
    }
    setState(() => busy = true);
    try {
      final repository = ref.read(operationsViewModelProvider);
      final idProofUrl = idProof == null
          ? null
          : await repository.upload(
              filePath: idProof!.path,
              filename: idProof!.name,
              purpose: 'tenant-document',
            );
      final agreementUrl = agreement == null
          ? null
          : await repository.upload(
              filePath: agreement!.path,
              filename: agreement!.name,
              purpose: 'tenant-document',
            );
      await repository.createResident({
        'propertyId': property,
        'firstName': first.text.trim(),
        'lastName': last.text.trim(),
        'mobile': mobile.text.trim(),
        if (email.text.trim().isNotEmpty) 'email': email.text.trim(),
        if (whatsapp.text.trim().isNotEmpty)
          'whatsappNumber': whatsapp.text.trim(),
        if (emergency.text.trim().isNotEmpty)
          'emergencyContact': emergency.text.trim(),
        if (address.text.trim().isNotEmpty)
          'permanentAddress': address.text.trim(),
        if (parentName.text.trim().isNotEmpty)
          'parentName': parentName.text.trim(),
        if (parentPhone.text.trim().isNotEmpty)
          'parentPhone': parentPhone.text.trim(),
        'profession': profession,
        'monthlyRent': parseRupees(rent.text),
        'securityDeposit': parseRupees(deposit.text),
        'joiningDate': joining.toIso8601String().substring(0, 10),
        'rentDueDay': int.parse(dueDay.text),
        'idProofUrl': ?idProofUrl,
        'agreementUrl': ?agreementUrl,
        if (roomId != null) 'roomId': roomId,
        if (bedId != null) 'bedId': bedId,
      });
      ref.invalidate(residentsProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider).asData?.value ?? [];
    final selectedRoom = rooms.where((r) => r.id == roomId).firstOrNull;
    final beds =
        selectedRoom?.beds.where((b) => b.status == 'AVAILABLE').toList() ?? [];
    return Scaffold(
      appBar: const PgHeader(title: 'Add tenant'),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PgField('First name', controller: first, validator: requiredText),
            PgField('Last name', controller: last),
            PgField(
              'Mobile',
              controller: mobile,
              keyboardType: TextInputType.phone,
              validator: mobileValidator,
            ),
            PgField(
              'Email',
              controller: email,
              keyboardType: TextInputType.emailAddress,
            ),
            PgField(
              'WhatsApp number',
              controller: whatsapp,
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.isEmpty
                  ? null
                  : mobileValidator(value),
            ),
            PgField(
              'Emergency contact',
              controller: emergency,
              keyboardType: TextInputType.phone,
            ),
            DropdownButtonFormField<String>(
              initialValue: profession,
              decoration: const InputDecoration(labelText: 'Profession'),
              items:
                  ['STUDENT', 'WORKING_PROFESSIONAL', 'SELF_EMPLOYED', 'OTHER']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.replaceAll('_', ' ')),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => profession = value!),
            ),
            const SizedBox(height: 12),
            PgField(
              'Monthly rent (₹)',
              controller: rent,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (tryParseRupees(v) ?? 0) > 0 ? null : 'Enter a positive rent',
            ),
            PgField(
              'Security deposit (₹)',
              controller: deposit,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (tryParseRupees(v) ?? -1) >= 0 ? null : 'Enter an amount',
            ),
            PgField(
              'Rent due day (1–28)',
              controller: dueDay,
              keyboardType: TextInputType.number,
              validator: (value) {
                final day = int.tryParse(value ?? '');
                return day != null && day >= 1 && day <= 28
                    ? null
                    : 'Choose a day from 1 to 28';
              },
            ),
            PgField('Permanent address', controller: address, maxLines: 2),
            PgField('Parent name', controller: parentName),
            PgField(
              'Parent phone',
              controller: parentPhone,
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.isEmpty
                  ? null
                  : mobileValidator(value),
            ),
            _DocumentPicker(
              label: 'ID proof',
              file: idProof,
              onPicked: (file) => setState(() => idProof = file),
            ),
            _DocumentPicker(
              label: 'Rental agreement',
              file: agreement,
              onPicked: (file) => setState(() => agreement = file),
            ),
            DropdownButtonFormField<String>(
              initialValue: roomId,
              decoration: const InputDecoration(labelText: 'Room (optional)'),
              items: rooms
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.roomNumber),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                roomId = v;
                bedId = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: bedId,
              decoration: const InputDecoration(
                labelText: 'Available bed (optional)',
              ),
              items: beds
                  .map(
                    (b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.bedNumber)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => bedId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Joining date'),
              subtitle: Text(joining.toIso8601String().substring(0, 10)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: joining,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => joining = date);
              },
            ),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Add tenant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({
    required this.label,
    required this.file,
    required this.onPicked,
  });
  final String label;
  final XFile? file;
  final ValueChanged<XFile> onPicked;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      onPressed: () async {
        final selected = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 2400,
        );
        if (selected != null) onPicked(selected);
      },
      icon: const Icon(Icons.upload_file_outlined),
      label: Text(file?.name ?? 'Upload $label'),
    ),
  );
}

class TenantDetailScreen extends ConsumerWidget {
  const TenantDetailScreen({super.key, required this.id, this.initialTab = 0});
  final String id;
  final int initialTab;
  void editProfile(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => FractionallySizedBox(
      heightFactor: .94,
      child: ActionScreen(
        name: 'edit-tenant',
        query: {'residentId': id},
        onSaved: () => Navigator.of(sheet).pop(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => PgAsync(
    value: ref.watch(residentProvider(id)),
    placeholder: Scaffold(
      appBar: AppBar(title: const Text('Tenant')),
      body: const TenantSkeleton(TenantPlaceholder.document),
    ),
    retry: () => ref.invalidate(residentProvider(id)),
    data: (person) => DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${person.firstName} ${person.lastName ?? ''} · ${tenantRoom(person)}',
          ),
          toolbarHeight: 72,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 56, top: 53),
              child: Text(
                person.property?.name ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Joining form'),
              Tab(text: 'Profile Details'),
              Tab(text: 'Passbook'),
              Tab(text: 'Activity Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JoiningForm(person),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TenantQuickActions(
                  person: person,
                  child: PgCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Text(person.firstName[0]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${person.firstName} ${person.lastName ?? ''}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(tenantRoom(person)),
                        Text(
                          'Rent ${rupees(person.monthlyRent)}  ·  Deposit ${rupees(person.securityDeposit)}',
                        ),
                        Text(
                          'DOJ ${shortDate(person.joiningDate)}  ·  DOL ${shortDate(person.moveOutDate ?? person.expectedVacatingDate)}',
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Call',
                              onPressed: () => launchUrl(
                                Uri(scheme: 'tel', path: person.mobile),
                              ),
                              icon: const Icon(Icons.call),
                            ),
                            IconButton(
                              tooltip: 'WhatsApp',
                              onPressed: () => context.push(
                                '/action/message?residentId=${person.id}',
                              ),
                              icon: const Icon(Icons.chat),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => editProfile(context),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Invite',
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(
                                  text:
                                      'Hi ${person.firstName}, access your PgInfo tenant account using mobile ${person.mobile}.',
                                  subject: 'PgInfo invitation',
                                ),
                              ),
                              icon: const Icon(Icons.person_add_alt_1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _AutopayCard(person),
                ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: const Text('WhatsApp reminder history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => _ReminderHistory(person.id),
                  ),
                ),
                const _SectionTitle('Personal details'),
                ListTile(
                  title: const Text('Mobile'),
                  subtitle: Text(person.mobile),
                ),
                if (person.email != null)
                  ListTile(
                    title: const Text('Email'),
                    subtitle: Text(person.email!),
                  ),
                if (person.whatsappNumber != null)
                  ListTile(
                    title: const Text('WhatsApp'),
                    subtitle: Text(person.whatsappNumber!),
                  ),
                ListTile(
                  title: const Text('Profession'),
                  subtitle: Text(person.profession ?? 'OTHER'),
                ),
                if (person.permanentAddress != null)
                  ListTile(
                    title: const Text('Permanent address'),
                    subtitle: Text(person.permanentAddress!),
                  ),
                const _SectionTitle('Rental details'),
                ListTile(
                  title: const Text('Room'),
                  subtitle: Text(
                    person.room == null
                        ? 'Not allocated'
                        : 'Room ${person.room!.roomNumber}${person.bed == null ? '' : ' • Bed ${person.bed!.bedNumber}'}',
                  ),
                ),
                ListTile(
                  title: const Text('Status'),
                  subtitle: Text(person.status ?? '—'),
                ),
                ListTile(
                  title: const Text('Security deposit'),
                  subtitle: Text(rupees(person.securityDeposit)),
                ),
                ListTile(
                  title: const Text('Rent due day'),
                  subtitle: Text('${person.rentDueDay ?? 'Property default'}'),
                ),
                const _SectionTitle('Parent and emergency details'),
                ListTile(
                  title: const Text('Parent'),
                  subtitle: Text(person.parentName ?? 'Not provided'),
                ),
                ListTile(
                  title: const Text('Parent phone'),
                  subtitle: Text(person.parentPhone ?? 'Not provided'),
                ),
                ListTile(
                  title: const Text('Emergency contact'),
                  subtitle: Text(person.emergencyContact ?? 'Not provided'),
                ),
                const _SectionTitle('Documents'),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('ID proof'),
                  subtitle: Text(
                    person.idProofUrl == null
                        ? 'Not uploaded'
                        : 'View document',
                  ),
                  onTap: person.idProofUrl == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(person.idProofUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Rental agreement'),
                  subtitle: Text(
                    person.agreementUrl == null
                        ? 'Not uploaded'
                        : 'View document',
                  ),
                  onTap: person.agreementUrl == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(person.agreementUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                ),
                FilledButton(
                  onPressed: () => editProfile(context),
                  child: const Text('Edit profile or upload documents'),
                ),
              ],
            ),
            _Passbook(person),
            _Activity(entityType: 'Resident', entityId: id),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _JoiningForm extends StatelessWidget {
  const _JoiningForm(this.person);
  final Resident person;

  Map<String, Map<String, String>> get sections => {
    'Personal details': {
      'Name': '${person.firstName} ${person.lastName ?? ''}'.trim(),
      'Mobile': person.mobile,
      'Email': person.email ?? '—',
      'Address': person.permanentAddress ?? '—',
      'Profession': person.profession ?? '—',
      'Parent': person.parentName ?? '—',
      'Parent phone': person.parentPhone ?? '—',
      'Emergency contact': person.emergencyContact ?? '—',
    },
    'Stay and payment details': {
      'Property': person.property?.name ?? '—',
      'Allocation': tenantRoom(person),
      'Joining date': shortDate(person.joiningDate),
      'Expected move-out': shortDate(person.expectedVacatingDate),
      'Monthly rent': rupees(person.monthlyRent),
      'Security deposit': rupees(person.securityDeposit),
      'Rent due day': '${person.rentDueDay ?? "Property default"}',
      'Remarks': person.notes ?? '—',
    },
  };

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      PgCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant joining form',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Text(person.property?.name ?? ''),
            for (final section in sections.entries) ...[
              _SectionTitle(section.key),
              for (final row in section.value.entries)
                ListTile(title: Text(row.key), subtitle: Text(row.value)),
            ],
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: () async {
          try {
            final document = pw.Document();
            for (final section in sections.entries) {
              document.addPage(
                pw.MultiPage(
                  header: (_) => pw.Header(
                    level: 0,
                    text: person.property?.name ?? 'Tenant joining form',
                  ),
                  build: (_) => [
                    pw.Header(level: 1, text: section.key),
                    for (final row in section.value.entries)
                      pw.Paragraph(
                        text:
                            '${row.key}: ${row.value.replaceAll('₹', 'INR ')}',
                      ),
                  ],
                ),
              );
            }
            final directory = await getTemporaryDirectory();
            final file = File(
              '${directory.path}${Platform.pathSeparator}joining-form-${person.id}.pdf',
            );
            await file.writeAsBytes(await document.save(), flush: true);
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path, mimeType: 'application/pdf')],
                subject: 'Tenant joining form',
              ),
            );
          } catch (error) {
            if (context.mounted) showError(context, error);
          }
        },
        icon: const Icon(Icons.download_outlined),
        label: const Text('Download or share'),
      ),
    ],
  );
}

class _Activity extends ConsumerWidget {
  const _Activity({required this.entityType, required this.entityId});
  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = pagedListProvider(
      PagedQuery(
        path: '/dashboard/activity',
        entityType: entityType,
        filterName: 'entityId',
        filterValue: entityId,
      ),
    );
    return PgAsync(
      value: ref.watch(provider),
      placeholder: const SingleChildScrollView(
        child: TenantSkeleton(TenantPlaceholder.fields),
      ),
      retry: () => ref.invalidate(provider),
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text('No activity recorded yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length + 1,
          itemBuilder: (context, index) {
            if (index == events.length) {
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
                child: const Text('Load more activity'),
              );
            }
            final event = events[index];
            final metadata = event['metadata'];
            final reason = metadata is Map ? metadata['reason'] : null;
            final date = DateTime.tryParse('${event['createdAt']}')?.toLocal();
            final local = MaterialLocalizations.of(context);
            final description = [
              if (date != null)
                '${local.formatMediumDate(date)} · ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
              if (event['actor'] != null) '${event['actor']}',
              if (reason != null) '$reason',
            ].join('\n');
            return PgCard(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  '${event['action']}'.replaceAll(RegExp(r'[._]'), ' '),
                ),
                subtitle: Text(description),
              ),
            );
          },
        );
      },
    );
  }
}

String shortDate(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null ? '—' : parsed.toIso8601String().substring(0, 10);
}

String tenantRoom(Resident person) => person.room == null
    ? 'Unallocated'
    : 'Room ${person.room!.roomNumber}${person.bed == null ? '' : ' · Bed ${person.bed!.bedNumber}'}';

final _reminderHistory = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, id) => ref
          .watch(repositoryProvider)
          .list('/announcements/reminders/whatsapp/$id'),
    );

class _ReminderHistory extends ConsumerWidget {
  const _ReminderHistory(this.residentId);
  final String residentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('WhatsApp reminder history'),
            trailing: IconButton(
              tooltip: 'Refresh delivery status',
              onPressed: () => ref.invalidate(_reminderHistory(residentId)),
              icon: const Icon(Icons.refresh),
            ),
          ),
          Expanded(
            child: PgAsync(
              value: ref.watch(_reminderHistory(residentId)),
              placeholder: const TenantSkeleton(TenantPlaceholder.fields),
              retry: () => ref.invalidate(_reminderHistory(residentId)),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text('No accepted WhatsApp reminders yet.'),
                    )
                  : ListView(
                      children: [
                        for (final item in items)
                          ListTile(
                            title: Text(
                              item['kind'] == 'autopay'
                                  ? 'Autopay reminder'
                                  : 'Rent reminder',
                            ),
                            subtitle: Text(_reminderStatus(item['status'])),
                            trailing: Text(
                              _reminderDate(context, item['requestedAt']),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  String _reminderStatus(Object? status) => switch (status) {
    'sent' => 'Sent by WhatsApp',
    'delivered' => 'Delivered',
    'read' => 'Read',
    'failed' => 'Delivery failed',
    _ => 'Accepted by provider',
  };

  String _reminderDate(BuildContext context, Object? raw) {
    final instant = raw is String ? DateTime.tryParse(raw) : null;
    return instant == null
        ? ''
        : MaterialLocalizations.of(context).formatShortDate(instant.toLocal());
  }
}

final _autopayMandates = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, id) => ref
          .watch(repositoryProvider)
          .list(
            '/rent/mandates',
            query: {'tenantId': id, 'limit': 100, 'collectionMode': 'AUTOPAY'},
          ),
    );

class _AutopayCard extends ConsumerStatefulWidget {
  const _AutopayCard(this.person);
  final Resident person;

  @override
  ConsumerState<_AutopayCard> createState() => _AutopayCardState();
}

class _AutopayCardState extends ConsumerState<_AutopayCard> {
  bool busy = false;

  Future<void> setup() async {
    final person = widget.person;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Autopay setup?'),
        content: Text(
          '${person.firstName} will need to authorize a monthly mandate '
          'for ${rupees(person.monthlyRent)}. The request uses UPI and covers 11 payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Create request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref.read(operationsViewModelProvider).create(
      '/rent/mandates/create',
      {
        'tenantId': person.id,
        'rentAmount': person.monthlyRent,
        'billingDay': person.rentDueDay ?? 5,
        'sendWhatsAppNotification': false,
      },
    ) as Map;
    ref.invalidate(_autopayMandates(person.id));
    if (!mounted) return;
    if (result['shortUrl'] case final String url) await share(url);
  }

  Future<void> share(String url) => SharePlus.instance.share(
    ShareParams(
      text:
          'Hi ${widget.person.firstName}, use this link to authorize rent Autopay: $url',
      subject: 'PgInfo rent Autopay setup',
    ),
  );

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    if (person.rentalFrequencyMonths > 1) {
      return const PgCard(
        child: ListTile(
          leading: Icon(Icons.autorenew),
          title: Text('Autopay setup'),
          subtitle: Text(
            'Available for monthly rental plans. Use a payment link for this tenant.',
          ),
        ),
      );
    }
    if (person.autopayActive) {
      return const PgCard(
        child: ListTile(
          leading: Icon(Icons.autorenew),
          title: Text('Autopay setup'),
          subtitle: Text('Active'),
        ),
      );
    }
    return PgCard(
      child: PgAsync(
        value: ref.watch(_autopayMandates(person.id)),
        placeholder: const PgSkeleton(height: 66),
        retry: () => ref.invalidate(_autopayMandates(person.id)),
        data: (items) {
          final relevant = items.where(
            (item) => item['propertyId'] == person.propertyId,
          );
          final active = relevant.any((item) => item['status'] == 'ACTIVE');
          final pending = relevant
              .where(
                (item) => const [
                  'CREATED',
                  'PENDING',
                  'AUTHENTICATED',
                ].contains(item['status']),
              )
              .firstOrNull;
          final url = pending?['shortUrl'];
          final awaiting = pending?['status'] == 'AUTHENTICATED';
          final canRequest = const [
            'ACTIVE',
            'NOTICE_PERIOD',
            'PENDING_MOVE_IN',
          ].contains(person.status);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.autorenew),
                title: const Text('Autopay setup'),
                subtitle: Text(
                  active
                      ? 'Active'
                      : awaiting
                      ? 'Authorization received'
                      : pending != null
                      ? 'Awaiting authorization'
                      : 'Not set up',
                ),
              ),
              if (canRequest && !active && !awaiting)
                Wrap(
                  spacing: 8,
                  children: [
                    if (pending == null)
                      FilledButton(
                        onPressed: busy ? null : () => run(setup),
                        child: const Text('Request setup'),
                      ),
                    if (url is String) ...[
                      TextButton.icon(
                        onPressed: busy ? null : () => run(() => share(url)),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share setup link'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => run(
                                () => remindTenant(
                                  context,
                                  ref,
                                  person.id,
                                  kind: 'autopay',
                                ),
                              ),
                        child: const Text('Remind for Autopay'),
                      ),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> remindTenant(
  BuildContext context,
  WidgetRef ref,
  String id, {
  String kind = 'rent',
}) async {
  try {
    final result = await ref.read(operationsViewModelProvider).create(
      '/announcements/reminders/rent',
      {
        'residentId': id,
        'kind': kind,
        'channel': kind == 'rent' ? 'WHATSAPP' : 'BOTH',
      },
    ) as Map;
    if (context.mounted) {
      ref.invalidate(_reminderHistory(id));
      final whatsapp = result['whatsapp'] as Map?;
      final email = result['email'] as Map?;
      final message = switch (result) {
        {'missingMandates': final int missing} when missing > 0 =>
          'Create an Autopay mandate before sending the WhatsApp invite.',
        {'whatsappError': final String error} => error,
        _ when whatsapp?['accepted'] == 1 => 'WhatsApp accepted the reminder',
        _ when email?['accepted'] == 1 => 'Email accepted the reminder',
        _ => 'No reminder was accepted',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (error) {
    if (context.mounted) showError(context, error);
  }
}

enum _LedgerView {
  ledger('Tenant Ledger'),
  dues('Tenant Dues'),
  collection('Total Collection'),
  advance('Current Advance'),
  deposit('Current Deposit'),
  discount('Total Discount');

  const _LedgerView(this.label);
  final String label;
}

class _Passbook extends ConsumerStatefulWidget {
  const _Passbook(this.person);
  final Resident person;

  @override
  ConsumerState<_Passbook> createState() => _PassbookState();
}

class _PassbookState extends ConsumerState<_Passbook> {
  _LedgerView view = _LedgerView.dues;
  String get id => widget.person.id;
  bool reminding = false;

  String recordPath({String? bill, required int amount}) =>
      '/action/record?residentId=$id&amount=$amount${bill == null ? '' : '&billingRecordId=$bill'}';

  int amount(Map<String, dynamic> row, String field) =>
      (row[field] as num?)?.toInt() ?? 0;

  int remaining(Map<String, dynamic> row) =>
      amount(row, 'amount') - amount(row, 'paidAmount');

  Future<void> editEntry({List<Map<String, dynamic>>? dues}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _PassbookEntry(person: widget.person, dues: dues),
      ),
    );
    if (saved != true || !mounted) return;
    ref.invalidate(tenantLedgerProvider(id));
    ref.invalidate(residentProvider(id));
    ref.invalidate(pagedListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(activityProvider((entityType: 'Resident', entityId: id)));
  }

  @override
  Widget build(BuildContext context) => PgAsync(
    value: ref.watch(tenantLedgerProvider(id)),
    placeholder: const SingleChildScrollView(
      child: TenantSkeleton(TenantPlaceholder.ledger),
    ),
    retry: () => ref.invalidate(tenantLedgerProvider(id)),
    data: (ledger) {
      final charges = ledger['dues'] ?? [];
      final payments = (ledger['payments'] ?? [])
          .where((row) => row['status'] == 'CONFIRMED')
          .toList();
      final validCharges = charges
          .where((row) => row['status'] != 'CANCELLED')
          .toList();
      final dues = validCharges.where((row) => remaining(row) > 0).toList();
      final outstanding = dues.fold(0, (sum, row) => sum + remaining(row));
      final collected = payments.fold(
        0,
        (sum, row) => sum + amount(row, 'amount'),
      );
      final allocated = validCharges.fold(
        0,
        (sum, row) => sum + amount(row, 'paidAmount'),
      );
      final advance = (collected - allocated).clamp(0, collected);
      final deposits = validCharges
          .where((row) => row['type'] == 'SECURITY_DEPOSIT')
          .toList();
      final deposit = deposits.fold(
        0,
        (sum, row) => sum + amount(row, 'paidAmount'),
      );
      final discounts = validCharges
          .where((row) => amount(row, 'discountAmount') > 0)
          .toList();
      final discounted = discounts.fold(
        0,
        (sum, row) => sum + amount(row, 'discountAmount'),
      );
      final values = {
        _LedgerView.ledger: '${charges.length + payments.length} entries',
        _LedgerView.dues: rupees(outstanding),
        _LedgerView.collection: rupees(collected),
        _LedgerView.advance: rupees(advance),
        _LedgerView.deposit: rupees(deposit),
        _LedgerView.discount: rupees(discounted),
      };
      final rows = switch (view) {
        _LedgerView.ledger => [
          ...charges,
          ...payments,
        ]..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}')),
        _LedgerView.dues => dues,
        _LedgerView.collection => payments,
        _LedgerView.advance => <Map<String, dynamic>>[],
        _LedgerView.deposit => deposits,
        _LedgerView.discount => discounts,
      };
      return Column(
        children: [
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final item in _LedgerView.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: item == view,
                      onSelected: (_) => setState(() => view = item),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(values[item]!), Text(item.label)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              key: ValueKey(view),
              itemCount: rows.isEmpty ? 1 : rows.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                if (rows.isEmpty) {
                  return ListTile(
                    title: Text(
                      view == _LedgerView.advance
                          ? rupees(advance)
                          : 'No entries',
                    ),
                    subtitle: view == _LedgerView.advance
                        ? const Text(
                            'Confirmed collections minus amounts applied to charges.',
                          )
                        : null,
                  );
                }
                final row = rows[index];
                final payment = row.containsKey('collectionDate');
                final rent = row['type'] == 'RENT';
                final date = DateTime.tryParse('${row['dueDate']}');
                final title = payment
                    ? 'Payment · ${row['mode']}'
                    : rent && date != null
                    ? '${MaterialLocalizations.of(context).formatMonthYear(date)} rent'
                    : (row['description'] as String?)?.trim().isNotEmpty == true
                    ? row['description'] as String
                    : '${row['type']}'.replaceAll('_', ' ');
                final displayAmount = switch (view) {
                  _LedgerView.dues => remaining(row),
                  _LedgerView.discount => amount(row, 'discountAmount'),
                  _LedgerView.deposit => amount(row, 'paidAmount'),
                  _ => amount(row, 'amount'),
                };
                return PgCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(title),
                        subtitle: Text(
                          payment
                              ? shortDate(row['collectionDate'])
                              : '${row['status']} · Due ${shortDate(row['dueDate'])}${row['addedBy'] == null ? '' : '\nAdded by ${row['addedBy']}'}',
                        ),
                        trailing: Text(rupees(displayAmount)),
                        onTap: payment
                            ? () => context.push(
                                '/action/receipt?id=${row['id']}',
                              )
                            : null,
                      ),
                      if (payment)
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/action/receipt?id=${row['id']}'),
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('View or share receipt'),
                        ),
                      if (view == _LedgerView.dues)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => context.push(
                                recordPath(
                                  bill: '${row['id']}',
                                  amount: remaining(row),
                                ),
                              ),
                              child: const Text('Record Now'),
                            ),
                            OutlinedButton(
                              onPressed: reminding
                                  ? null
                                  : () async {
                                      setState(() => reminding = true);
                                      await remindTenant(context, ref, id);
                                      if (mounted) {
                                        setState(() => reminding = false);
                                      }
                                    },
                              child: const Text('Remind to Pay'),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => context.push('/action/due?residentId=$id'),
                    child: const Text('Add Dues'),
                  ),
                  TextButton(
                    onPressed: outstanding == 0
                        ? null
                        : () => context.push(recordPath(amount: outstanding)),
                    child: const Text('Record All'),
                  ),
                  TextButton(
                    onPressed: dues.isEmpty
                        ? null
                        : () => editEntry(dues: dues),
                    child: const Text('Give Discount'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More passbook actions',
                    onSelected: (value) => value == 'fine'
                        ? context.push(
                            '/action/due?residentId=$id&type=LATE_FEE',
                          )
                        : editEntry(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'fine',
                        child: Text('Add Late Fine'),
                      ),
                      PopupMenuItem(
                        value: 'remarks',
                        child: Text('Add Remarks'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PassbookEntry extends ConsumerStatefulWidget {
  const _PassbookEntry({required this.person, this.dues});
  final Resident person;
  final List<Map<String, dynamic>>? dues;

  @override
  ConsumerState<_PassbookEntry> createState() => _PassbookEntryState();
}

class _PassbookEntryState extends ConsumerState<_PassbookEntry> {
  late final remarks = TextEditingController(
    text: widget.dues == null ? widget.person.notes : null,
  );
  final amount = TextEditingController();
  late String? bill = widget.dues?.firstOrNull?['id'] as String?;
  bool busy = false;

  @override
  void dispose() {
    remarks.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final note = remarks.text.trim();
    final discount = tryParseRupees(amount.text);
    if (widget.dues != null &&
        (bill == null || discount == null || discount <= 0 || note.isEmpty)) {
      showError(context, 'Enter a positive amount and a reason');
      return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(operationsViewModelProvider);
      if (widget.dues == null) {
        await repo.updateResident(widget.person.id, {'notes': note});
      } else {
        await repo.create('/billing/records/$bill/discount', {
          'amount': discount,
          'reason': note,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dues = widget.dues;
    return Scaffold(
      appBar: AppBar(
        title: Text(dues == null ? 'Tenant remarks' : 'Give Discount'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (dues != null) ...[
            DropdownButtonFormField<String>(
              initialValue: bill,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Charge'),
              items: [
                for (final due in dues)
                  DropdownMenuItem(
                    value: due['id'] as String,
                    child: Text(
                      '${due['type']} · ${shortDate(due['dueDate'])} · ${rupees((due['amount'] as num) - (due['paidAmount'] as num))}',
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => bill = value),
            ),
            const SizedBox(height: 12),
            PgField(
              'Discount amount (₹)',
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
          ],
          PgField(
            dues == null ? 'Remarks' : 'Reason',
            controller: remarks,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}
