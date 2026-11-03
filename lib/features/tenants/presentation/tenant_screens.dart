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
  const TenantDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PgAsync(
    value: ref.watch(residentProvider(id)),
    retry: () => ref.invalidate(residentProvider(id)),
    data: (person) => DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${person.firstName} ${person.lastName ?? ''}'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Joining form'),
              Tab(text: 'Profile'),
              Tab(text: 'Passbook'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JoiningForm(person),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PgCard(
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
                      Text(
                        'Rent ${rupees(person.monthlyRent)} • Joined ${person.joiningDate?.substring(0, 10) ?? '—'}',
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
                            onPressed: () => context.push(
                              '/action/edit-tenant?residentId=${person.id}',
                            ),
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
                  onPressed: () =>
                      context.push('/action/due?residentId=${person.id}'),
                  child: const Text('Add due'),
                ),
              ],
            ),
            _Passbook(id),
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

  String get content =>
      '''PgInfo tenant joining form

Name: ${person.firstName} ${person.lastName ?? ''}
Mobile: ${person.mobile}
Joining date: ${person.joiningDate?.substring(0, 10) ?? '—'}
Monthly rent: ${rupees(person.monthlyRent)}
Room: ${person.roomId ?? 'Not allocated'}
Status: ${person.status ?? '—'}
Tenant reference: ${person.id}''';

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
            SelectableText(content),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: () async {
          try {
            final document = pw.Document();
            document.addPage(
              pw.MultiPage(
                build: (_) => [
                  pw.Header(level: 0, text: 'PgInfo tenant joining form'),
                  pw.Text(content.replaceAll('₹', 'INR ')),
                ],
              ),
            );
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
  Widget build(BuildContext context, WidgetRef ref) => PgAsync(
    value: ref.watch(
      activityProvider((entityType: entityType, entityId: entityId)),
    ),
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
              title: Text(
                '${event['action']}'.replaceAll('.', ' ').toUpperCase(),
              ),
              subtitle: Text('${event['createdAt']}'),
            ),
          );
        },
      );
    },
  );
}

class _Passbook extends ConsumerWidget {
  const _Passbook(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PgAsync(
    value: ref.watch(tenantLedgerProvider(id)),
    retry: () => ref.invalidate(tenantLedgerProvider(id)),
    data: (ledger) {
      final dues = ledger['dues'] ?? [], payments = ledger['payments'] ?? [];
      final outstanding = dues.fold<int>(
        0,
        (sum, e) =>
            sum +
            ((e['amount'] as num).toInt() - (e['paidAmount'] as num).toInt()),
      );
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MetricCard(label: 'Outstanding dues', value: rupees(outstanding)),
          const SizedBox(height: 16),
          Text('Charges', style: Theme.of(context).textTheme.titleMedium),
          for (final due in dues)
            PgCard(
              child: ListTile(
                title: Text('${due['type']} • ${rupees(due['amount'] as num)}'),
                subtitle: Text('${due['status']} • Due ${due['dueDate']}'),
              ),
            ),
          const SizedBox(height: 16),
          Text('Payments', style: Theme.of(context).textTheme.titleMedium),
          for (final payment in payments)
            PgCard(
              child: ListTile(
                title: Text(rupees(payment['amount'] as num)),
                subtitle: Text('${payment['mode']} • ${payment['status']}'),
                onTap: () =>
                    context.push('/action/receipt?id=${payment['id']}'),
              ),
            ),
          FilledButton(
            onPressed: () => context.push('/action/record?residentId=$id'),
            child: const Text('Record payment'),
          ),
        ],
      );
    },
  );
}
