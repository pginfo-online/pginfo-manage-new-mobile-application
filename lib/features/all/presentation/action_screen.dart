import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/di/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';
import '../../tenants/presentation/tenant_skeleton.dart';

class ActionScreen extends ConsumerStatefulWidget {
  const ActionScreen({
    super.key,
    required this.name,
    required this.query,
    this.onSaved,
  });
  final VoidCallback? onSaved;
  final String name;
  final Map<String, String> query;
  @override
  ConsumerState<ActionScreen> createState() => _ActionState();
}

class _ActionState extends ConsumerState<ActionScreen> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  String? selectedResident, categoryId, designationId;
  String? organizationId;
  String? announcementId;
  String mode = 'CASH', type = 'OTHER', role = 'VIEWER';
  String recordStatus = 'NEW';
  DateTime date = DateTime.now();
  bool busy = false;
  bool routeTermsAccepted = false;
  bool profileReady = false;
  Object? profileError;
  XFile? formAttachment;
  XFile? idProofAttachment;
  XFile? agreementAttachment;
  late final String paymentKey = const Uuid().v4();
  TextEditingController field(String key) =>
      fields.putIfAbsent(key, () => TextEditingController());
  @override
  void initState() {
    super.initState();
    selectedResident = widget.query['residentId'];
    if (widget.query['type'] == 'LATE_FEE') type = 'LATE_FEE';
    final amount = int.tryParse(widget.query['amount'] ?? '');
    if (amount != null) {
      field('amount').text = (amount / 100).toStringAsFixed(2);
    }
    if (widget.name == 'complaint-new') type = 'MEDIUM';
    if (widget.name == 'bank') type = 'individual';
    if (widget.name == 'edit-tenant' && selectedResident != null) {
      Future.microtask(loadProfile);
    }
    if (widget.name == 'expense' && widget.query['id'] != null) {
      Future.microtask(() async {
        try {
          final expense = await ref
              .read(operationsViewModelProvider)
              .expense(widget.query['id']!);
          if (!mounted) return;
          field('amount').text = ((expense['amount'] as num) / 100)
              .toStringAsFixed(2);
          field('description').text = '${expense['description'] ?? ''}';
          field('paidBy').text = '${expense['paidBy'] ?? ''}';
          field('paidTo').text = '${expense['paidTo'] ?? ''}';
          setState(() {
            categoryId = expense['categoryId'] as String?;
            mode = expense['paymentMode'] as String? ?? 'CASH';
            date =
                DateTime.tryParse('${expense['expenseDate']}') ??
                DateTime.now();
          });
        } catch (e) {
          if (mounted) showError(context, e);
        }
      });
    }
    if (widget.name == 'lead' && widget.query['id'] != null) {
      Future.microtask(() async {
        try {
          final lead = await ref
              .read(operationsViewModelProvider)
              .lead(widget.query['id']!);
          if (!mounted) return;
          for (final key in [
            'name',
            'mobile',
            'email',
            'sharingPreference',
            'source',
            'notes',
          ]) {
            field(key).text = '${lead[key] ?? ''}';
          }
          if (lead['budget'] != null) {
            field('budget').text = ((lead['budget'] as num) / 100)
                .toStringAsFixed(2);
          }
          setState(() => recordStatus = lead['status'] as String? ?? 'NEW');
        } catch (e) {
          if (mounted) showError(context, e);
        }
      });
    }
    if (widget.name == 'staff' && widget.query['id'] != null) {
      Future.microtask(() async {
        try {
          final staff = await ref
              .read(operationsViewModelProvider)
              .staff(widget.query['id']!);
          if (!mounted) return;
          for (final key in [
            'firstName',
            'lastName',
            'mobile',
            'email',
            'notes',
          ]) {
            field(key).text = '${staff[key] ?? ''}';
          }
          if (staff['salary'] != null) {
            field('salary').text = ((staff['salary'] as num) / 100)
                .toStringAsFixed(2);
          }
          setState(() {
            designationId = staff['designationId'] as String?;
            recordStatus = staff['status'] as String? ?? 'ACTIVE';
          });
        } catch (e) {
          if (mounted) showError(context, e);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get label => widget.name.replaceAll('-', ' ').replaceAll('_', ' ');
  String dateText() => date.toIso8601String().substring(0, 10);
  Widget input(
    String key,
    String title, {
    bool required = true,
    bool money = false,
    bool phone = false,
    int lines = 1,
  }) => PgField(
    title,
    controller: field(key),
    maxLines: lines,
    keyboardType: money
        ? TextInputType.number
        : phone
        ? TextInputType.phone
        : null,
    validator: required
        ? (money
              ? (v) => (tryParseRupees(v) ?? 0) > 0
                    ? null
                    : 'Enter a positive amount'
              : phone
              ? mobileValidator
              : requiredText)
        : null,
  );
  Widget choice(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> onChange,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: title),
      items: options
          .map(
            (v) =>
                DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' '))),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChange(v);
      },
    ),
  );
  Widget dateTile(String title) => ListTile(
    title: Text(title),
    subtitle: Text(dateText()),
    trailing: const Icon(Icons.calendar_month),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => date = picked);
    },
  );
  Future<void> loadProfile() async {
    if (selectedResident == null || !mounted) return;
    setState(() => profileError = null);
    try {
      final person = await ref
          .read(operationsViewModelProvider)
          .residentDetails(selectedResident!);
      if (!mounted) return;
      for (final key in [
        'firstName',
        'lastName',
        'mobile',
        'email',
        'whatsappNumber',
        'emergencyContact',
        'permanentAddress',
        'parentName',
        'parentPhone',
        'notes',
      ]) {
        field(key).text = '${person[key] ?? ''}';
      }
      field('monthlyRent').text = ((person['monthlyRent'] as num) / 100)
          .toStringAsFixed(2);
      field('rentDueDay').text = '${person['rentDueDay'] ?? ''}';
      setState(() {
        type = person['profession'] as String? ?? 'OTHER';
        profileReady = true;
      });
    } catch (error) {
      if (mounted) setState(() => profileError = error);
    }
  }

  Widget residentSelect() => widget.query['residentId'] != null
      ? Consumer(
          builder: (context, ref, _) => PgAsync(
            value: ref.watch(residentProvider(widget.query['residentId']!)),
            data: (person) => ListTile(
              title: Text(
                '${person.firstName} ${person.lastName ?? ""}'.trim(),
              ),
            ),
          ),
        )
      : Consumer(
          builder: (context, ref, _) => PgAsync(
            value: ref.watch(residentsProvider),
            data: (people) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: selectedResident,
                decoration: const InputDecoration(labelText: 'Tenant'),
                items: people
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.firstName} ${p.lastName ?? ''}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedResident = v),
              ),
            ),
          ),
        );
  Widget attachmentPicker(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      onPressed: busy
          ? null
          : () async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 88,
                maxWidth: 2400,
              );
              if (file != null && mounted) {
                setState(() => formAttachment = file);
              }
            },
      icon: const Icon(Icons.attach_file),
      label: Text(formAttachment?.name ?? label),
    ),
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final repo = ref.read(operationsViewModelProvider),
        property = ref.read(selectedPropertyProvider);
    setState(() => busy = true);
    try {
      switch (widget.name) {
        case 'due':
          if (selectedResident == null) {
            throw const ApiFailure('Choose a tenant', null);
          }
          await repo.create('/billing/charges', {
            'residentId': selectedResident,
            'type': type,
            'amount': parseRupees(field('amount').text),
            'dueDate': dateText(),
            'description': field('description').text.trim(),
          });
          ref.invalidate(dashboardProvider);
          ref.invalidate(tenantLedgerProvider(selectedResident!));
          ref.invalidate(pagedListProvider);
          break;
        case 'record':
        case 'collect':
          if (selectedResident == null) {
            throw const ApiFailure('Choose a tenant', null);
          }
          final proofUrl = formAttachment == null
              ? null
              : await repo.upload(
                  filePath: formAttachment!.path,
                  filename: formAttachment!.name,
                  purpose: 'payment-proof',
                );
          await repo.create('/payments/record', {
            'residentId': selectedResident,
            if (widget.query['billingRecordId'] != null)
              'billingRecordId': widget.query['billingRecordId'],
            'amount': parseRupees(field('amount').text),
            'mode': mode,
            'collectionDate': dateText(),
            'notes': field('notes').text.trim(),
            'proofUrl': ?proofUrl,
            'idempotencyKey': paymentKey,
          });
          ref.invalidate(dashboardProvider);
          ref.invalidate(residentsProvider);
          ref.invalidate(tenantLedgerProvider(selectedResident!));
          ref.invalidate(pagedListProvider);
          break;
        case 'expense':
          if (property == null || categoryId == null) {
            throw const ApiFailure(
              'Choose a property and expense category',
              null,
            );
          }
          final receiptUrl = formAttachment == null
              ? null
              : await repo.upload(
                  filePath: formAttachment!.path,
                  filename: formAttachment!.name,
                  purpose: 'expense-receipt',
                );
          final body = {
            'propertyId': property,
            'categoryId': categoryId,
            'amount': parseRupees(field('amount').text),
            'expenseDate': dateText(),
            'paymentMode': mode,
            'paidBy': field('paidBy').text.trim(),
            'paidTo': field('paidTo').text.trim(),
            'description': field('description').text.trim(),
            'receiptUrl': ?receiptUrl,
          };
          if (widget.query['id'] == null) {
            await repo.create('/expenses', body);
          } else {
            await repo.update('/expenses/${widget.query['id']}', body);
          }
          ref.invalidate(dashboardProvider);
          break;
        case 'lead':
          if (property == null && widget.query['id'] == null) {
            throw const ApiFailure('Choose a property', null);
          }
          final leadBody = <String, dynamic>{
            'name': field('name').text.trim(),
            'mobile': field('mobile').text.trim(),
            if (field('email').text.trim().isNotEmpty)
              'email': field('email').text.trim(),
            if (field('budget').text.trim().isNotEmpty)
              'budget': parseRupees(field('budget').text),
            if (field('sharingPreference').text.trim().isNotEmpty)
              'sharingPreference': field('sharingPreference').text.trim(),
            if (field('source').text.trim().isNotEmpty)
              'source': field('source').text.trim(),
            'notes': field('notes').text.trim(),
          };
          if (widget.query['id'] == null) {
            await repo.create('/leads', {'propertyId': property, ...leadBody});
          } else {
            await repo.update('/leads/${widget.query['id']}', {
              ...leadBody,
              'status': recordStatus,
            });
          }
          break;
        case 'staff':
          if (property == null || designationId == null) {
            throw const ApiFailure('Choose a property and designation', null);
          }
          final staffBody = <String, dynamic>{
            'designationId': designationId,
            'firstName': field('firstName').text.trim(),
            'lastName': field('lastName').text.trim(),
            'mobile': field('mobile').text.trim(),
            if (field('email').text.trim().isNotEmpty)
              'email': field('email').text.trim(),
            if (field('salary').text.trim().isNotEmpty)
              'salary': parseRupees(field('salary').text),
            'notes': field('notes').text.trim(),
          };
          if (widget.query['id'] == null) {
            await repo.create('/staff', {'propertyId': property, ...staffBody});
          } else {
            await repo.update('/staff/${widget.query['id']}', {
              ...staffBody,
              'status': recordStatus,
            });
          }
          break;
        case 'complaint-new':
          if (property == null || categoryId == null) {
            throw const ApiFailure('Choose a property and category', null);
          }
          await repo.create('/complaints', {
            'propertyId': property,
            'categoryId': categoryId,
            'description': field('description').text.trim(),
            'urgency': type,
          });
          ref.invalidate(dashboardProvider);
          break;
        case 'announcements':
          if (announcementId == null) {
            final created = await repo.create('/announcements', {
              'title': field('title').text.trim(),
              'body': field('body').text.trim(),
              'scope': property == null ? 'ORGANIZATION' : 'PROPERTY',
              'propertyId': ?property,
            }) as Map<String, dynamic>;
            announcementId = created['id'] as String;
          }
          await repo.create('/announcements/$announcementId/send', {});
          break;
        case 'bank':
          if (!routeTermsAccepted) {
            throw const ApiFailure(
              'Accept Razorpay Route terms to continue',
              null,
            );
          }
          await repo.create('/payouts/onboard-owner', {
            'routeTermsAccepted': routeTermsAccepted,
            'ownerName': field('ownerName').text.trim(),
            'email': field('email').text.trim(),
            'phone': field('phone').text.trim(),
            'businessName': field('businessName').text.trim(),
            'businessType': type,
            'accountNumber': field('accountNumber').text.trim(),
            'ifscCode': field('ifscCode').text.trim().toUpperCase(),
            if (field('panNumber').text.trim().isNotEmpty)
              'panNumber': field('panNumber').text.trim().toUpperCase(),
            'propertyId': ?property,
          });
          break;
        case 'team':
          final orgId =
              organizationId ?? ref.read(selectedOrganizationProvider);
          if (orgId == null) {
            throw const ApiFailure('Choose an organization', null);
          }
          await repo.create('/organizations/$orgId/members', {
            'email': field('email').text.trim(),
            'role': role,
          });
          ref.invalidate(membersProvider(orgId));
          break;
        case 'edit-tenant':
          final id = widget.query['residentId'];
          if (id == null) throw const ApiFailure('Tenant missing', null);
          final idProofUrl = idProofAttachment == null
              ? null
              : await repo.upload(
                  filePath: idProofAttachment!.path,
                  filename: idProofAttachment!.name,
                  purpose: 'tenant-document',
                );
          final agreementUrl = agreementAttachment == null
              ? null
              : await repo.upload(
                  filePath: agreementAttachment!.path,
                  filename: agreementAttachment!.name,
                  purpose: 'tenant-document',
                );
          await repo.updateResident(id, {
            'firstName': field('firstName').text.trim(),
            'lastName': field('lastName').text.trim(),
            'mobile': field('mobile').text.trim(),
            if (field('email').text.trim().isNotEmpty)
              'email': field('email').text.trim(),
            if (field('whatsappNumber').text.trim().isNotEmpty)
              'whatsappNumber': field('whatsappNumber').text.trim(),
            if (field('emergencyContact').text.trim().isNotEmpty)
              'emergencyContact': field('emergencyContact').text.trim(),
            if (field('permanentAddress').text.trim().isNotEmpty)
              'permanentAddress': field('permanentAddress').text.trim(),
            if (field('parentName').text.trim().isNotEmpty)
              'parentName': field('parentName').text.trim(),
            if (field('parentPhone').text.trim().isNotEmpty)
              'parentPhone': field('parentPhone').text.trim(),
            'idProofUrl': ?idProofUrl,
            'agreementUrl': ?agreementUrl,
            'monthlyRent': parseRupees(field('monthlyRent').text),
            if (field('rentDueDay').text.trim().isNotEmpty)
              'rentDueDay': int.parse(field('rentDueDay').text.trim()),
            'profession': type,
            'notes': field('notes').text.trim(),
          });
          ref.invalidate(residentsProvider);
          ref.invalidate(residentProvider(id));
          ref.invalidate(pagedListProvider);
          break;
        default:
          return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved successfully')));
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (widget.name) {
      case 'due':
        content = Column(
          children: [
            residentSelect(),
            choice('Due type', type, [
              'RENT',
              'SECURITY_DEPOSIT',
              'ELECTRICITY',
              'WATER',
              'MAINTENANCE',
              'LATE_FEE',
              'OTHER',
            ], (v) => setState(() => type = v)),
            input('amount', 'Amount (₹)', money: true),
            dateTile('Due date'),
            input('description', 'Description'),
          ],
        );
        break;
      case 'record':
      case 'collect':
        content = Column(
          children: [
            residentSelect(),
            if (selectedResident != null)
              _PaymentSummary(
                residentId: selectedResident!,
                amount: field('amount'),
              ),
            input('amount', 'Amount received (₹)', money: true),
            dateTile('Collection date'),
            choice('Collection mode', mode, [
              'CASH',
              'UPI',
              'BANK_TRANSFER',
              'CHEQUE',
              'OTHER',
            ], (v) => setState(() => mode = v)),
            input('notes', 'Description', required: false),
            attachmentPicker('Attach payment proof'),
          ],
        );
        break;
      case 'expense':
        content = Column(
          children: [
            input('amount', 'Amount (₹)', money: true),
            dateTile('Expense date'),
            _CategorySelect(
              value: categoryId,
              onChanged: (v) => setState(() => categoryId = v),
            ),
            choice('Payment mode', mode, [
              'CASH',
              'UPI',
              'BANK_TRANSFER',
              'CHEQUE',
              'OTHER',
            ], (v) => setState(() => mode = v)),
            input('paidBy', 'Paid by', required: false),
            input('paidTo', 'Paid to', required: false),
            input('description', 'Description'),
            attachmentPicker('Attach receipt'),
          ],
        );
        break;
      case 'lead':
        content = Column(
          children: [
            input('name', 'Lead name'),
            input('mobile', 'Mobile', phone: true),
            input('email', 'Email', required: false),
            input('budget', 'Budget (₹)', required: false),
            input('sharingPreference', 'Sharing preference', required: false),
            input('source', 'Source', required: false),
            if (widget.query['id'] != null)
              choice('Status', recordStatus, [
                'NEW',
                'CONTACTED',
                'VISITED',
                'TOKEN_PAID',
                'CONVERTED',
                'LOST',
              ], (v) => setState(() => recordStatus = v)),
            input('notes', 'Notes', required: false, lines: 3),
          ],
        );
        break;
      case 'staff':
        content = Column(
          children: [
            _CategorySelect(
              path: '/staff/designations',
              label: 'Designation',
              value: designationId,
              onChanged: (v) => setState(() => designationId = v),
            ),
            input('firstName', 'First name'),
            input('lastName', 'Last name', required: false),
            input('mobile', 'Mobile', phone: true),
            input('email', 'Email', required: false),
            input('salary', 'Salary (₹)', required: false),
            if (widget.query['id'] != null)
              choice('Status', recordStatus, [
                'ACTIVE',
                'INACTIVE',
                'TERMINATED',
              ], (v) => setState(() => recordStatus = v)),
            input('notes', 'Notes', required: false, lines: 3),
          ],
        );
        break;
      case 'complaint-new':
        content = Column(
          children: [
            _CategorySelect(
              path: '/complaints/categories',
              onChanged: (v) => setState(() => categoryId = v),
            ),
            choice('Urgency', type, [
              'LOW',
              'MEDIUM',
              'HIGH',
              'CRITICAL',
            ], (v) => setState(() => type = v)),
            input('description', 'Describe the issue', lines: 4),
          ],
        );
        break;
      case 'announcements':
        content = Column(
          children: [
            input('title', 'Title'),
            input('body', 'Message', lines: 5),
          ],
        );
        break;
      case 'bank':
        content = Column(
          children: [
            input('ownerName', 'Owner name'),
            input('email', 'Email'),
            input('phone', 'Phone', phone: true),
            input('businessName', 'Business name'),
            choice('Payee type', type, [
              'individual',
              'proprietorship',
              'partnership',
              'llp',
              'private_limited',
            ], (value) => setState(() => type = value)),
            PgField(
              'Account number',
              controller: field('accountNumber'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  RegExp(r'^\d{9,18}$').hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Enter a 9 to 18 digit account number',
            ),
            PgField(
              'IFSC code',
              controller: field('ifscCode'),
              validator: (value) =>
                  RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
                      .hasMatch(value?.trim().toUpperCase() ?? '')
                  ? null
                  : 'Enter a valid IFSC code',
            ),
            PgField(
              'PAN number (if applicable)',
              controller: field('panNumber'),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ||
                      RegExp(r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$')
                          .hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Enter a valid PAN',
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.https('razorpay.com', '/terms/')),
              child: const Text('Read Razorpay terms'),
            ),
            CheckboxListTile(
              value: routeTermsAccepted,
              onChanged: busy
                  ? null
                  : (value) =>
                        setState(() => routeTermsAccepted = value ?? false),
              title: const Text(
                'I am authorized to accept Razorpay terms for this account',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        );
        break;
      case 'team':
        content = Column(
          children: [
            PgAsync(
              value: ref.watch(organizationsProvider),
              data: (items) => DropdownButtonFormField<String>(
                initialValue: organizationId,
                decoration: const InputDecoration(labelText: 'Organization'),
                items: items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['id'] as String,
                        child: Text('${e['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => organizationId = v),
              ),
            ),
            const SizedBox(height: 12),
            input('email', 'Member email'),
            choice('Role', role, [
              'ADMIN',
              'MANAGER',
              'STAFF',
              'VIEWER',
            ], (v) => setState(() => role = v)),
          ],
        );
        break;
      case 'edit-tenant':
        if (!profileReady) {
          content = profileError == null
              ? const TenantSkeleton(TenantPlaceholder.fields)
              : Column(
                  children: [
                    Text(profileError.toString()),
                    TextButton(
                      onPressed: loadProfile,
                      child: const Text('Retry loading profile'),
                    ),
                  ],
                );
          break;
        }
        content = Column(
          children: [
            input('firstName', 'First name'),
            input('lastName', 'Last name', required: false),
            input('mobile', 'Mobile', phone: true),
            input('email', 'Email', required: false),
            input(
              'whatsappNumber',
              'WhatsApp number',
              required: false,
              phone: true,
            ),
            input('emergencyContact', 'Emergency contact', required: false),
            input(
              'permanentAddress',
              'Permanent address',
              required: false,
              lines: 2,
            ),
            input('parentName', 'Parent name', required: false),
            input('parentPhone', 'Parent phone', required: false, phone: true),
            input('monthlyRent', 'Monthly rent (₹)', money: true),
            PgField(
              'Rent due day (1–28)',
              controller: field('rentDueDay'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final day = int.tryParse(v);
                return day != null && day >= 1 && day <= 28
                    ? null
                    : 'Use a day from 1 to 28';
              },
            ),
            choice('Profession', type, [
              'STUDENT',
              'WORKING_PROFESSIONAL',
              'SELF_EMPLOYED',
              'OTHER',
            ], (v) => setState(() => type = v)),
            input('notes', 'Notes', required: false, lines: 3),
            OutlinedButton.icon(
              onPressed: () async {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 90,
                  maxWidth: 2400,
                );
                if (file != null && mounted) {
                  setState(() => idProofAttachment = file);
                }
              },
              icon: const Icon(Icons.badge_outlined),
              label: Text(idProofAttachment?.name ?? 'Replace ID proof'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 90,
                  maxWidth: 2400,
                );
                if (file != null && mounted) {
                  setState(() => agreementAttachment = file);
                }
              },
              icon: const Icon(Icons.description_outlined),
              label: Text(
                agreementAttachment?.name ?? 'Replace rental agreement',
              ),
            ),
          ],
        );
        break;
      case 'message':
        return _MessageScreen(residentId: widget.query['residentId']);
      case 'reminders':
        return _ReminderScreen(kind: widget.query['kind']);
      case 'complaints':
        return const _ComplaintListScreen();
      case 'complaint':
        return _ComplaintDetailScreen(id: widget.query['id']);
      case 'notifications':
        return const _NotificationsScreen();
      case 'receipt':
        return _ReceiptScreen(id: widget.query['id']);
      case 'report':
        return _ReportScreen(
          type: widget.query['type'] ?? 'collections',
          propertyId: widget.query['propertyId'],
        );
      default:
        return Scaffold(
          appBar: PgHeader(title: label),
          body: const Center(
            child: Text(
              'This workflow is not available through the current backend API.',
            ),
          ),
        );
    }
    return Scaffold(
      appBar: PgHeader(title: label),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            content,
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy || (widget.name == 'edit-tenant' && !profileReady)
                  ? null
                  : save,
              child: Text(
                busy
                    ? 'Saving…'
                    : widget.name == 'announcements'
                    ? 'Send announcement'
                    : 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelect extends ConsumerWidget {
  const _CategorySelect({
    required this.onChanged,
    this.value,
    this.path = '/expenses/categories',
    this.label = 'Category',
  });
  final ValueChanged<String?> onChanged;
  final String? value;
  final String path;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(operationsViewModelProvider).list(path),
        builder: (context, snap) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            key: ValueKey(value),
            initialValue: snap.data?.any((e) => e['id'] == value) == true
                ? value
                : null,
            decoration: InputDecoration(labelText: label),
            items: (snap.data ?? [])
                .map(
                  (e) => DropdownMenuItem(
                    value: e['id'] as String,
                    child: Text('${e['name']}'),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}

class _MessageScreen extends ConsumerStatefulWidget {
  const _MessageScreen({this.residentId});
  final String? residentId;
  @override
  ConsumerState<_MessageScreen> createState() => _MessageState();
}

class _MessageState extends ConsumerState<_MessageScreen> {
  final message = TextEditingController();
  final phone = TextEditingController();
  XFile? attachment;
  @override
  void dispose() {
    message.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = [
      'Welcome to your new home!',
      'Please set up autopay for rent.',
      'Please complete your KYC and agreement.',
      'Download the PgInfo app for updates.',
      'Your rent payment is due. Please pay soon.',
      'A late fee has been added to your account.',
      'Happy birthday!',
      'Hello, an update about your family member.',
    ];
    return Scaffold(
      appBar: const PgHeader(title: 'WhatsApp message'),
      body: FutureBuilder<Resident?>(
        future: widget.residentId == null
            ? Future.value(null)
            : ref
                  .read(operationsViewModelProvider)
                  .resident(widget.residentId!),
        builder: (context, snap) {
          if (phone.text.isEmpty && snap.data?.mobile != null) {
            phone.text = snap.data!.mobile;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final t in templates)
                ListTile(title: Text(t), onTap: () => message.text = t),
              PgField('Phone', controller: phone, validator: mobileValidator),
              PgField('Edit message', controller: message, maxLines: 5),
              OutlinedButton.icon(
                onPressed: () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null && mounted) {
                    setState(() => attachment = image);
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(
                  attachment == null ? 'Attach image' : attachment!.name,
                ),
              ),
              if (attachment != null)
                TextButton(
                  onPressed: () => setState(() => attachment = null),
                  child: const Text('Remove attachment'),
                ),
              FilledButton(
                onPressed: () async {
                  if (mobileValidator(phone.text) != null ||
                      message.text.trim().isEmpty) {
                    showError(context, 'Enter a valid phone and message');
                    return;
                  }
                  if (attachment != null) {
                    await SharePlus.instance.share(
                      ShareParams(text: message.text, files: [attachment!]),
                    );
                  } else {
                    final uri = Uri.parse(
                      'https://wa.me/91${phone.text}?text=${Uri.encodeComponent(message.text)}',
                    );
                    if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        ) &&
                        context.mounted) {
                      showError(context, 'WhatsApp is unavailable');
                    }
                  }
                },
                child: Text(
                  attachment == null
                      ? 'My WhatsApp'
                      : 'Share media (select WhatsApp)',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  if (message.text.trim().isEmpty) return;
                  await SharePlus.instance.share(
                    ShareParams(
                      text: message.text,
                      files: attachment == null ? null : [attachment!],
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Other apps'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderScreen extends ConsumerStatefulWidget {
  const _ReminderScreen({this.kind});
  final String? kind;
  @override
  ConsumerState<_ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<_ReminderScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final propertyId = ref.watch(selectedPropertyProvider);
    final autopay = widget.kind == 'autopay';
    final title = autopay ? 'Bulk Autopay reminders' : 'Bulk payment reminders';
    return Scaffold(
      appBar: PgHeader(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                propertyId == null
                    ? 'All properties in this organization'
                    : 'Currently selected property',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          final result =
                              await ref
                                      .read(operationsViewModelProvider)
                                      .create('/announcements/reminders/rent', {
                                        'propertyId': ?propertyId,
                                        'kind': autopay ? 'autopay' : 'rent',
                                        'channel': widget.kind == 'whatsapp'
                                            ? 'WHATSAPP'
                                            : 'BOTH',
                                      })
                                  as Map;
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'WhatsApp: ${(result['whatsapp'] as Map?)?['accepted'] ?? 0} accepted. '
                                'Email: ${(result['email'] as Map?)?['accepted'] ?? 0} accepted. '
                                '${result['failedCount'] ?? 0} failed. '
                                '${result['missingMandates'] ?? 0} without a pending mandate.',
                              ),
                            ),
                          );
                          this.context.pop();
                        } catch (error) {
                          if (mounted) showError(this.context, error);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: Text(busy ? 'Sending…' : 'Send reminders'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplaintListScreen extends ConsumerWidget {
  const _ComplaintListScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const PgHeader(title: 'Complaints'),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/action/complaint-new'),
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: ref
          .read(operationsViewModelProvider)
          .list(
            '/complaints',
            query: {
              if (ref.read(selectedPropertyProvider) != null)
                'propertyId': ref.read(selectedPropertyProvider),
            },
          ),
      builder: (context, snap) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (snap.hasError) Text(snap.error.toString()),
          if (!snap.hasData && !snap.hasError)
            const Center(child: CircularProgressIndicator()),
          if (snap.hasData)
            for (final complaint in snap.data!)
              PgCard(
                onTap: () =>
                    context.push('/action/complaint?id=${complaint['id']}'),
                child: ListTile(
                  title: Text('${complaint['description']}'),
                  subtitle: Text(
                    '${complaint['status']} • ${complaint['urgency']}',
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class _ComplaintDetailScreen extends ConsumerStatefulWidget {
  const _ComplaintDetailScreen({required this.id});
  final String? id;
  @override
  ConsumerState<_ComplaintDetailScreen> createState() =>
      _ComplaintDetailState();
}

class _ComplaintDetailState extends ConsumerState<_ComplaintDetailScreen> {
  late Future<Map<String, dynamic>> future;
  final notes = TextEditingController();
  @override
  void initState() {
    super.initState();
    future = ref.read(operationsViewModelProvider).complaint(widget.id ?? '');
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  void reload() => setState(
    () => future = ref
        .read(operationsViewModelProvider)
        .complaint(widget.id ?? ''),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PgHeader(title: 'Complaint details'),
    body: widget.id == null
        ? const Center(child: Text('Complaint unavailable'))
        : FutureBuilder<Map<String, dynamic>>(
            future: future,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text(snap.error.toString()));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final item = snap.data!;
              const transitions = <String, List<String>>{
                'RECEIVED': [
                  'VERIFIED',
                  'TEAM_WORKING',
                  'NEED_MORE_TIME',
                  'RESOLVED',
                ],
                'VERIFIED': [
                  'TEAM_WORKING',
                  'NEED_MORE_TIME',
                  'PENDING',
                  'RESOLVED',
                ],
                'TEAM_WORKING': ['NEED_MORE_TIME', 'PENDING', 'RESOLVED'],
                'NEED_MORE_TIME': ['TEAM_WORKING', 'PENDING', 'RESOLVED'],
                'PENDING': ['TEAM_WORKING', 'RESOLVED'],
                'RESOLVED': ['RECEIVED'],
              };
              final allowed = transitions[item['status']] ?? <String>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  PgCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['description']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('${item['status']} • ${item['urgency']}'),
                        if (item['resolution'] != null)
                          ListTile(
                            title: const Text('Resolution'),
                            subtitle: Text('${item['resolution']}'),
                          ),
                      ],
                    ),
                  ),
                  if (allowed.isNotEmpty) ...[
                    PgField(
                      'Notes or resolution',
                      controller: notes,
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Change status',
                      ),
                      items: allowed
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (status) async {
                        if (status == null) return;
                        try {
                          await ref.read(operationsViewModelProvider).update(
                            '/complaints/${widget.id}/status',
                            {
                              'status': status,
                              'notes': notes.text.trim(),
                              if (status == 'RESOLVED')
                                'resolution': notes.text.trim(),
                            },
                          );
                          ref.invalidate(dashboardProvider);
                          reload();
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final event in (item['history'] as List? ?? []))
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        '${event['fromStatus']} → ${event['toStatus']}',
                      ),
                      subtitle: Text('${event['notes'] ?? ''}'),
                    ),
                  for (final comment in (item['comments'] as List? ?? []))
                    ListTile(
                      leading: const Icon(Icons.comment_outlined),
                      title: Text('${comment['content']}'),
                    ),
                ],
              );
            },
          ),
  );
}

class _NotificationsScreen extends ConsumerWidget {
  const _NotificationsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const PgHeader(title: 'Notifications'),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: ref
          .read(operationsViewModelProvider)
          .list(
            '/announcements',
            query: {
              if (ref.read(selectedPropertyProvider) != null)
                'propertyId': ref.read(selectedPropertyProvider),
            },
          ),
      builder: (context, snap) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (snap.hasError) Text(snap.error.toString()),
          if (!snap.hasData && !snap.hasError)
            const Center(child: CircularProgressIndicator()),
          if (snap.hasData && snap.data!.isEmpty)
            const ListTile(title: Text('No announcements yet')),
          if (snap.hasData)
            for (final item in snap.data!)
              PgCard(
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text('${item['title']}'),
                  subtitle: Text('${item['body']}\n${item['status']}'),
                ),
              ),
        ],
      ),
    ),
  );
}

class _ReceiptScreen extends ConsumerWidget {
  const _ReceiptScreen({required this.id});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const PgHeader(title: 'Payment receipt'),
    body: id == null
        ? const Center(child: Text('Receipt unavailable'))
        : FutureBuilder<dynamic>(
            future: ref.read(operationsViewModelProvider).receipt(id!),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text(snap.error.toString()));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = Map<String, dynamic>.from(snap.data as Map);
              final resident = data['resident'] is Map
                  ? Map<String, dynamic>.from(data['resident'] as Map)
                  : <String, dynamic>{};
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  PgCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt ${data['receiptNumber'] ?? id}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Tenant'),
                          subtitle: Text('${resident['name'] ?? '—'}'),
                        ),
                        ListTile(
                          title: const Text('Property'),
                          subtitle: Text('${resident['property'] ?? '—'}'),
                        ),
                        ListTile(
                          title: const Text('Amount'),
                          subtitle: Text(
                            '${data['amountFormatted'] ?? rupees((data['amountPaise'] as num?) ?? 0)}',
                          ),
                        ),
                        ListTile(
                          title: const Text('Mode'),
                          subtitle: Text('${data['mode'] ?? '—'}'),
                        ),
                        ListTile(
                          title: const Text('Collection date'),
                          subtitle: Text('${data['collectionDate'] ?? '—'}'),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: data.toString()),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receipt copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy receipt details'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'PgInfo receipt\n${resident['name'] ?? ''}\n${data['amountFormatted'] ?? ''}\n${data['collectionDate'] ?? ''}',
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share receipt'),
                  ),
                ],
              );
            },
          ),
  );
}

class _ReportScreen extends ConsumerWidget {
  const _ReportScreen({required this.type, this.propertyId});
  final String? propertyId;
  final String type;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeType = ['collections', 'residents', 'expenses'].contains(type)
        ? type
        : 'collections';
    return Scaffold(
      appBar: PgHeader(title: '$safeType report'),
      body: FutureBuilder<dynamic>(
        future: ref
            .read(repositoryProvider)
            .report(safeType, propertyId: propertyId),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snap.data.toString();
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(report),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: report));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy CSV'),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final directory = await getTemporaryDirectory();
                    final stamp = DateTime.now()
                        .toIso8601String()
                        .split('T')
                        .first;
                    final file = File(
                      '${directory.path}${Platform.pathSeparator}pginfo-$safeType-$stamp.csv',
                    );
                    await file.writeAsString(report, flush: true);
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(file.path, mimeType: 'text/csv')],
                        subject: 'PgInfo $safeType report',
                      ),
                    );
                  } catch (error) {
                    if (context.mounted) showError(context, error);
                  }
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download or share CSV'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentSummary extends ConsumerWidget {
  const _PaymentSummary({required this.residentId, required this.amount});
  final String residentId;
  final TextEditingController amount;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tenantLedgerProvider(residentId);
    return PgAsync(
      value: ref.watch(provider),
      placeholder: const TenantSkeleton(TenantPlaceholder.fields),
      retry: () => ref.invalidate(provider),
      data: (ledger) {
        final records = (ledger['dues'] ?? []).where(
          (record) =>
              record['status'] != 'CANCELLED' &&
              (record['amount'] as num) > (record['paidAmount'] as num),
        );
        final due = records.fold<int>(
          0,
          (total, e) =>
              total +
              ((e['amount'] as num).toInt() - (e['paidAmount'] as num).toInt()),
        );
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: amount,
          builder: (context, value, _) {
            final received = tryParseRupees(value.text) ?? 0;
            return PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total dues: ${rupees(due)}'),
                  Text('Net receivable: ${rupees(due)}'),
                  Text('Remaining: ${rupees((due - received).clamp(0, due))}'),
                  ExpansionTile(
                    title: const Text('View full breakup'),
                    children: [
                      for (final record in records)
                        ListTile(
                          title: Text('${record['type']}'),
                          trailing: Text(
                            rupees(
                              (record['amount'] as num) -
                                  (record['paidAmount'] as num),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
