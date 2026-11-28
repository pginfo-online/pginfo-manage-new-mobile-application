import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../app/di/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/components/common.dart';
import '../../../shared/models/models.dart';
import '../money_data.dart';
import 'money_widgets.dart';

String moneyDateText(DateTime date) => date.toIso8601String().substring(0, 10);

Widget moneyChoice(
  String label,
  String value,
  List<String> options,
  ValueChanged<String> onChanged,
) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    isExpanded: true,
    items: [
      for (final o in options)
        DropdownMenuItem(
          value: o,
          child: Text(switch (o) {
            'FULL' => 'Full Dues',
            'CUSTOM' => 'Custom Amount',
            'FIXED' => 'Fixed',
            'VARIABLE' => 'Variable',
            _ => o.replaceAll('_', ' '),
          }),
        ),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  ),
);

class MoneyEditor extends ConsumerStatefulWidget {
  const MoneyEditor({super.key, required this.kind, this.initial});
  final String kind;
  final MoneyRow? initial;
  @override
  ConsumerState<MoneyEditor> createState() => _MoneyEditorState();
}

class _MoneyEditorState extends ConsumerState<MoneyEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  TextEditingController field(String key) =>
      fields.putIfAbsent(key, () => TextEditingController());
  late String propertyType = 'PG',
      category = 'Rent',
      billing = 'FIXED',
      mode = 'CASH';
  String? categoryId, propertyId;
  bool active = true, busy = false;
  DateTime date = DateTime.now();
  XFile? attachment;
  String? uploadedUrl;
  @override
  void initState() {
    super.initState();
    date = ref.read(moneyNowProvider);
    propertyId = ref.read(selectedPropertyProvider);
    final initial = widget.initial;
    if (initial != null) {
      for (final k in ['name', 'description', 'paidBy', 'paidTo']) {
        field(k).text = '${initial[k] ?? ''}';
      }
      field('amount').text = (moneyInt(initial['amount']) / 100)
          .toStringAsFixed(2);
      propertyType = initial['propertyType'] as String? ?? 'PG';
      category = initial['category'] is String
          ? initial['category'] as String
          : 'Rent';
      billing = initial['billing'] as String? ?? 'FIXED';
      active = initial['isActive'] != false;
      categoryId = initial['categoryId'] as String?;
      mode = initial['paymentMode'] as String? ?? 'CASH';
      propertyId = initial['propertyId'] as String? ?? propertyId;
      date = DateTime.tryParse('${initial['expenseDate']}') ?? date;
    }
  }

  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  Widget input(
    String key,
    String label, {
    bool money = false,
    bool required = true,
    int lines = 1,
  }) => PgField(
    label,
    controller: field(key),
    maxLines: lines,
    keyboardType: money
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    validator: (v) => money
        ? (tryParseRupees(v ?? '') == null ? 'Enter a valid amount' : null)
        : required
        ? requiredText(v)
        : null,
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final package = widget.kind == 'package';
    if (!package && (propertyId == null || categoryId == null)) {
      showError(context, 'Select a property and category');
      return;
    }
    setState(() => busy = true);
    try {
      final api = ref.read(apiClientProvider);
      MoneyRow body;
      if (package) {
        body = {
          'name': field('name').text.trim(),
          'propertyType': propertyType,
          'category': category,
          'billing': billing,
          'amount': parseRupees(field('amount').text),
          'description': field('description').text.trim(),
          'isActive': active,
          'version': ?widget.initial?['version'],
        };
      } else {
        if (attachment != null && uploadedUrl == null) {
          uploadedUrl = await ref
              .read(repositoryProvider)
              .upload(
                filePath: attachment!.path,
                filename: attachment!.name,
                purpose: 'expense-receipt',
              );
        }
        body = {
          'propertyId': propertyId,
          'categoryId': categoryId,
          'amount': parseRupees(field('amount').text),
          'expenseDate': moneyDateText(date),
          'paymentMode': mode,
          'paidBy': field('paidBy').text.trim(),
          'paidTo': field('paidTo').text.trim(),
          'description': field('description').text.trim(),
          'receiptUrl': ?uploadedUrl,
        };
      }
      final path = package ? '/money/packages' : '/expenses';
      if (widget.initial == null) {
        await api.post(path, body);
      } else {
        await api.patch('$path/${widget.initial!['id']}', body);
      }
      if (!mounted) return;
      refreshMoney(ref);
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.kind == 'package';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: package
            ? null
            : Theme.of(context).colorScheme.surfaceContainerLow,
        foregroundColor: package
            ? null
            : Theme.of(context).colorScheme.onSurface,
        title: Text(
          package
              ? '${widget.initial == null ? 'Add' : 'Edit'} Due Package'
              : '${widget.initial == null ? 'Add' : 'Edit'} Expense',
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (package)
              PgCard(
                child: Column(
                  children: [
                    moneyChoice('Property Type', propertyType, [
                      'PG',
                      'HOSTEL',
                      'CO_LIVING',
                      'APARTMENT',
                      'FLAT',
                      'RK',
                      'OTHER',
                    ], (v) => setState(() => propertyType = v)),
                    input('name', 'Package Name'),
                    moneyChoice(
                      'Category',
                      category,
                      dueCategories,
                      (v) => setState(() => category = v),
                    ),
                    moneyChoice('Billing Details', billing, [
                      'FIXED',
                      'VARIABLE',
                    ], (v) => setState(() => billing = v)),
                    input(
                      'amount',
                      billing == 'VARIABLE'
                          ? 'Default Amount (₹)'
                          : 'Amount (₹)',
                      money: true,
                    ),
                    SwitchListTile(
                      title: const Text('Active package'),
                      value: active,
                      onChanged: (v) => setState(() => active = v),
                    ),
                    if (billing == 'VARIABLE')
                      const Text(
                        'Variable amounts are confirmed when adding a tenant’s dues.',
                      ),
                  ],
                ),
              )
            else ...[
              PgCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: field('amount'),
                        style: Theme.of(context).textTheme.headlineLarge,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Expense Amount',
                          hintText: 'Amount',
                          prefixText: '₹ ',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        validator: (v) {
                          final value = tryParseRupees(v ?? '');
                          return value == null || value <= 0
                              ? 'Enter an amount greater than zero'
                              : null;
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(moneyDateText(date)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final next = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (next != null) setState(() => date = next);
                      },
                    ),
                    MoneyCategoryPicker(
                      value: categoryId,
                      onChanged: (v) => setState(() => categoryId = v),
                    ),
                    moneyChoice(
                      'Payment Mode',
                      mode,
                      paymentModes,
                      (v) => setState(() => mode = v),
                    ),
                  ],
                ),
              ),
              PgCard(
                child: Column(
                  children: [
                    MoneyPartyField(
                      label: 'Paid By',
                      controller: field('paidBy'),
                    ),
                    MoneyPartyField(
                      label: 'Paid To',
                      controller: field('paidTo'),
                    ),
                    MoneyPropertyField(
                      value: propertyId,
                      onChanged: (v) => setState(() => propertyId = v),
                    ),
                  ],
                ),
              ),
            ],
            PgCard(
              child: Column(
                children: [
                  if (!package)
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final file = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 2400,
                                imageQuality: 85,
                              );
                              if (file != null && mounted) {
                                setState(() {
                                  attachment = file;
                                  uploadedUrl = null;
                                });
                              }
                            },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(attachment?.name ?? 'Upload Attachments'),
                    ),
                  input(
                    'description',
                    'Description',
                    required: !package,
                    lines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: busy ? null : save,
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ),
    );
  }
}

class MoneyCategoryPicker extends ConsumerWidget {
  const MoneyCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String? value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => MoneyAsync(
    value: ref.watch(moneyOptionsProvider('/expenses/categories')),
    compact: true,
    retry: () => ref.invalidate(moneyOptionsProvider('/expenses/categories')),
    builder: (items) => Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: items.any((i) => i['id'] == value) ? value : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final i in items)
              DropdownMenuItem(
                value: '${i['id']}',
                child: Text('${i['name']}'),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          validator: (v) => v == null ? 'Choose a category' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final name = await moneyNameDialog(
                context,
                'New expense category',
              );
              if (name == null) return;
              try {
                final result = moneyMap(
                  await ref.read(apiClientProvider).post(
                    '/expenses/categories',
                    {'name': name},
                  ),
                );
                ref.invalidate(moneyOptionsProvider('/expenses/categories'));
                onChanged('${result['id']}');
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create category'),
          ),
        ),
      ],
    ),
  );
}

Future<String?> moneyNameDialog(BuildContext context, String title) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(c, controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  // The route may still be animating out while its text field is mounted.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return result;
}

class MoneyPartyField extends ConsumerWidget {
  const MoneyPartyField({
    super.key,
    required this.label,
    required this.controller,
  });
  final String label;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.expand_more),
      ),
      onTap: () async {
        final name = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const MoneyPartyScreen()),
        );
        if (name != null) controller.text = name;
      },
    ),
  );
}

class MoneyPropertyField extends ConsumerWidget {
  const MoneyPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String? value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = value == null ? null : MoneyQuery('/money/properties/$value');
    final label = query == null
        ? 'Select Property'
        : ref
              .watch(moneyObjectProvider(query))
              .when(
                data: (p) => '${p['name']}',
                error: (e, _) => 'Unable to load property · Tap to select',
                loading: () => 'Loading property…',
              );
    return FormField<String>(
      key: ValueKey(value),
      initialValue: value,
      validator: (v) => v == null ? 'Select a property' : null,
      builder: (field) => InkWell(
        onTap: () async {
          final result = await Navigator.push<MoneyRow>(
            context,
            MaterialPageRoute(builder: (_) => const MoneyPropertyScreen()),
          );
          if (result != null) onChanged('${result['id']}');
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Property',
            errorText: field.errorText,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class MoneyPropertyScreen extends ConsumerStatefulWidget {
  const MoneyPropertyScreen({super.key, this.allowUnlink = false});
  final bool allowUnlink;
  @override
  ConsumerState<MoneyPropertyScreen> createState() => _MoneyPropertyState();
}

class _MoneyPropertyState extends ConsumerState<MoneyPropertyScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select Property')),
    body: MoneyList(
      query: MoneyQuery('/money/properties', {'search': search}),
      header: [
        SearchField(
          hint: 'Search properties',
          onChanged: (v) => setState(() => search = v.trim()),
        ),
        if (widget.allowUnlink)
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Organization default'),
            subtitle: const Text('Unlink this account from its property'),
            onTap: () => Navigator.pop(context, <String, dynamic>{'id': ''}),
          ),
        const SizedBox(height: 16),
      ],
      item: (p) => PgCard(
        onTap: () => Navigator.pop(context, p),
        child: ListTile(
          leading: const Icon(Icons.apartment),
          title: Text('${p['name']}'),
          subtitle: Text('${p['type']}'),
        ),
      ),
    ),
  );
}

class MoneyPartyScreen extends ConsumerStatefulWidget {
  const MoneyPartyScreen({super.key});
  @override
  ConsumerState<MoneyPartyScreen> createState() => _MoneyPartyState();
}

class _MoneyPartyState extends ConsumerState<MoneyPartyScreen> {
  String search = '';
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select party')),
    floatingActionButton: FloatingActionButton(
      onPressed: busy
          ? null
          : () async {
              final name = await moneyNameDialog(context, 'Create party');
              if (name == null) return;
              setState(() => busy = true);
              try {
                final result = moneyMap(
                  await ref.read(apiClientProvider).post('/money/parties', {
                    'name': name,
                  }),
                );
                if (context.mounted) {
                  Navigator.pop(context, '${result['name']}');
                }
              } catch (e) {
                if (context.mounted) {
                  showError(context, e);
                }
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
      child: busy ? const CircularProgressIndicator() : const Icon(Icons.add),
    ),
    body: MoneyList(
      query: MoneyQuery('/money/parties', {'search': search}),
      header: [
        SearchField(
          hint: 'Search names',
          onChanged: (v) => setState(() => search = v),
        ),
        const SizedBox(height: 16),
      ],
      item: (party) => PgCard(
        onTap: () => Navigator.pop(context, '${party['name']}'),
        child: Text('${party['name']}'),
      ),
    ),
  );
}

class RecordMoneyPaymentScreen extends ConsumerStatefulWidget {
  const RecordMoneyPaymentScreen({super.key, required this.residentId});
  final String residentId;
  @override
  ConsumerState<RecordMoneyPaymentScreen> createState() =>
      _RecordMoneyPaymentState();
}

class _RecordMoneyPaymentState extends ConsumerState<RecordMoneyPaymentScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController(), description = TextEditingController();
  final key = const Uuid().v4();
  String mode = 'CASH';
  DateTime date = DateTime.now();
  bool busy = false, initialized = false, custom = false;
  XFile? attachment;
  String? proof;
  Map<String, int> allocations = {};
  @override
  void initState() {
    super.initState();
    date = ref.read(moneyNowProvider);
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  int discount(MoneyRow data, int receiving) {
    final o = data['offer'];
    if (o == null) return 0;
    final value = moneyInt(o['amount']);
    return receiving >=
            (o['minimumPayment'] == 'FULL'
                ? moneyInt(data['totalDues']) - value
                : moneyInt(o['minimumAmount']))
        ? value
        : 0;
  }

  List<MoneyRow> bills(MoneyRow data) =>
      (data['bills'] as List).map(moneyMap).toList();
  void distribute(MoneyRow data) {
    var left = tryParseRupees(amount.text) ?? 0;
    allocations = {};
    for (final b in bills(data)) {
      final due = moneyInt(b['amount']) - moneyInt(b['paidAmount']);
      final take = left.clamp(0, due);
      if (take > 0) allocations['${b['id']}'] = take;
      left -= take;
    }
  }

  Future<void> breakup(MoneyRow data) async {
    final controllers = {
      for (final b in bills(data))
        '${b['id']}': TextEditingController(
          text: ((allocations['${b['id']}'] ?? 0) / 100).toStringAsFixed(2),
        ),
    };
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(c).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Payment Breakup', style: Theme.of(c).textTheme.titleLarge),
              for (final b in bills(data))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: controllers['${b['id']}'],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          '${b['type']} · ${moneyAmount(moneyInt(b['amount']) - moneyInt(b['paidAmount']))}',
                      helperText: 'Due ${'${b['dueDate']}'.split('T').first}',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final parsed = <String, int>{};
                  for (final b in bills(data)) {
                    final v = tryParseRupees(controllers['${b['id']}']!.text);
                    if (v == null ||
                        v > moneyInt(b['amount']) - moneyInt(b['paidAmount'])) {
                      showError(
                        c,
                        'Enter valid amounts within each bill’s balance',
                      );
                      return;
                    }
                    if (v > 0) parsed['${b['id']}'] = v;
                  }
                  if (parsed.values.fold(0, (s, v) => s + v) !=
                      (tryParseRupees(amount.text) ?? 0)) {
                    showError(
                      c,
                      'Breakup must equal the amount being received',
                    );
                    return;
                  }
                  Navigator.pop(c, parsed);
                },
                child: const Text('Apply breakup'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        allocations = result;
        custom = true;
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> save(MoneyRow data) async {
    if (!form.currentState!.validate()) return;
    final receiving = parseRupees(amount.text);
    final net = moneyInt(data['totalDues']) - discount(data, receiving);
    if (receiving <= 0 || receiving > net) {
      showError(
        context,
        'Amount must be greater than zero and within net receivable',
      );
      return;
    }
    if (!custom) distribute(data);
    if (allocations.values.fold(0, (s, v) => s + v) != receiving) {
      showError(context, 'Review payment breakup');
      return;
    }
    setState(() => busy = true);
    try {
      if (attachment != null && proof == null) {
        proof = await ref
            .read(repositoryProvider)
            .upload(
              filePath: attachment!.path,
              filename: attachment!.name,
              purpose: 'payment-proof',
            );
      }
      final result = moneyMap(
        await ref.read(apiClientProvider).post('/money/payments', {
          'residentId': widget.residentId,
          'amount': receiving,
          'mode': mode,
          'collectionDate': moneyDateText(date),
          'notes': description.text.trim(),
          'proofUrl': ?proof,
          'idempotencyKey': key,
          'allocations': [
            for (final a in allocations.entries)
              {'billingRecordId': a.key, 'amount': a.value},
          ],
        }),
      );
      if (!mounted) return;
      refreshMoney(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment recorded · ${(result['payments'] as List).length} bill(s) updated',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = MoneyQuery(
      '/money/residents/${widget.residentId}/payment-context',
    );
    final value = ref.watch(moneyObjectProvider(query));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record Payment'),
            Text(
              '${value.asData?.value['resident']?['property']?['name'] ?? ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: MoneyAsync(
        value: value,
        form: true,
        retry: () => ref.invalidate(moneyObjectProvider(query)),
        builder: (data) {
          if (!initialized) {
            final total = moneyInt(data['totalDues']);
            final d = data['offer'] == null
                ? 0
                : moneyInt(data['offer']['amount']);
            amount.text = ((total - d) / 100).toStringAsFixed(2);
            initialized = true;
            distribute(data);
          }
          final resident = moneyMap(data['resident']);
          final receiving = tryParseRupees(amount.text) ?? 0;
          final d = discount(data, receiving);
          final net = moneyInt(data['totalDues']) - d;
          return Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MoneyTenantCard(
                  resident: resident,
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Call tenant',
                        onPressed: () => moneyLaunch(
                          context,
                          Uri(scheme: 'tel', path: '${resident['mobile']}'),
                        ),
                        icon: const Icon(Icons.call_outlined),
                      ),
                      IconButton(
                        tooltip: 'WhatsApp tenant',
                        onPressed: () => moneyWhatsApp(
                          context,
                          '${resident['whatsappNumber'] ?? resident['mobile']}',
                          '',
                        ),
                        icon: const Icon(
                          Icons.chat_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                PgCard(
                  child: Column(
                    children: [
                      summaryLine('Total Dues', moneyInt(data['totalDues'])),
                      if (d > 0) summaryLine('Eligible Discount', d),
                      const Divider(height: 32),
                      summaryLine('Net Receivable', net),
                    ],
                  ),
                ),
                PgCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: amount,
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "I'm Receiving",
                          prefixText: '₹ ',
                        ),
                        validator: (v) => tryParseRupees(v ?? '') == null
                            ? 'Enter a valid amount'
                            : null,
                        onChanged: (_) => setState(() {
                          custom = false;
                          distribute(data);
                        }),
                      ),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            receiving == net ? 'Fully paid' : 'Partial payment',
                            style: TextStyle(
                              color: receiving == net ? Colors.green : null,
                            ),
                          ),
                          TextButton(
                            onPressed: () => breakup(data),
                            child: const Text('View Breakup ›'),
                          ),
                        ],
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Collection Date'),
                        subtitle: Text(moneyDateText(date)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final next = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (next != null) setState(() => date = next);
                        },
                      ),
                      moneyChoice(
                        'Collection Mode',
                        mode,
                        paymentModes,
                        (v) => setState(() => mode = v),
                      ),
                    ],
                  ),
                ),
                PgCard(
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                final file = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 2400,
                                  imageQuality: 85,
                                );
                                if (file != null && mounted) {
                                  setState(() {
                                    attachment = file;
                                    proof = null;
                                  });
                                }
                              },
                        icon: const Icon(Icons.upload_file),
                        label: Text(attachment?.name ?? 'Upload Attachment'),
                      ),
                      PgField(
                        'Description',
                        controller: description,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: busy || value.asData == null
                ? null
                : () => save(value.asData!.value),
            child: Text(busy ? 'Recording…' : 'Record Payment'),
          ),
        ),
      ),
    );
  }

  Widget summaryLine(String text, int value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(text)),
        Text(
          moneyAmount(value),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    ),
  );
}

Future<void> moneyLaunch(BuildContext context, Uri uri) async {
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      showError(context, 'Unable to open this app');
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Future<void> moneyWhatsApp(
  BuildContext context,
  String phone,
  String message,
) async {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) digits = '91$digits';
  if (digits.length < 10) {
    showError(context, 'No valid phone number on file');
    return;
  }
  await moneyLaunch(context, Uri.https('wa.me', '/$digits', {'text': message}));
}

Future<void> showMoneySheet(BuildContext context, String id, String action) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MoneyActionSheet(residentId: id, action: action),
    );

class MoneyActionSheet extends ConsumerStatefulWidget {
  const MoneyActionSheet({
    super.key,
    required this.residentId,
    required this.action,
  });
  final String residentId, action;
  @override
  ConsumerState<MoneyActionSheet> createState() => _MoneyActionState();
}

class _MoneyActionState extends ConsumerState<MoneyActionSheet> {
  final amount = TextEditingController(),
      minimum = TextEditingController(),
      description = TextEditingController();
  @override
  void initState() {
    super.initState();
    expiry = ref.read(moneyNowProvider).add(const Duration(days: 7));
  }

  String condition = 'FULL';
  DateTime expiry = DateTime.now().add(const Duration(days: 7));
  bool busy = false;
  @override
  void dispose() {
    amount.dispose();
    minimum.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> showPaymentQr() async {
    setState(() => busy = true);
    try {
      final response = moneyMap(
        await ref
            .read(apiClientProvider)
            .post('/money/residents/${widget.residentId}/payment-qr', {}),
      );
      if (!mounted) return;
      final url = response['qrImageUrl'] as String;
      final expiry = DateTime.tryParse('${response['expiresAt']}')?.toLocal();
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Scan to pay PGInfo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(moneyAmount(moneyInt(response['amount']))),
                const SizedBox(height: 12),
                Image.network(
                  url,
                  width: 210,
                  height: 210,
                  fit: BoxFit.contain,
                  semanticLabel: 'Razorpay UPI payment QR code',
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'Use Share QR to open or send the payment code.',
                    ),
                  ),
                ),
                if (expiry != null)
                  Text('Expires ${DateFormat.yMMMd().add_jm().format(expiry)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Close'),
            ),
            Builder(
              builder: (button) => FilledButton.icon(
                onPressed: () async {
                  try {
                    await SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Pay ${moneyAmount(moneyInt(response['amount']))} to PGInfo using this Razorpay UPI payment QR.\n$url',
                        sharePositionOrigin: moneyShareOrigin(button),
                      ),
                    );
                  } catch (error) {
                    if (dialog.mounted) showError(dialog, error);
                  }
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share QR'),
              ),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder =
        widget.action == 'Remind to Pay' || widget.action == 'Remind Parent';
    final query = MoneyQuery(
      '/money/residents/${widget.residentId}/${reminder ? 'reminder' : 'payment-context'}',
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .84,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.action,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              MoneyAsync(
                value: ref.watch(moneyObjectProvider(query)),
                compact: true,
                retry: () => ref.invalidate(moneyObjectProvider(query)),
                builder: (data) {
                  final r = moneyMap(data['resident']);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MoneyTenantCard(
                        resident: r,
                        trailing: Text(
                          moneyAmount(moneyInt(data['totalDues'])),
                        ),
                      ),
                      if (reminder) ...[
                        if (widget.action == 'Remind Parent')
                          ListTile(
                            leading: const Icon(Icons.family_restroom),
                            title: Text(
                              '${r['parentName'] ?? 'Parent details not added'}',
                            ),
                            subtitle: Text(
                              '${r['parentPhone'] ?? 'No phone number on file'}',
                            ),
                          ),
                        PgCard(
                          child: SelectableText(
                            widget.action == 'Remind Parent'
                                ? 'Hello ${r['parentName'] ?? 'Parent'}, ${moneyName(r)} has outstanding dues of ${moneyAmount(moneyInt(data['totalDues']))} at ${r['property']?['name']}. ${data['paymentLink'] ?? 'Please contact the property manager for payment details.'}'
                                : '${data['message']}',
                          ),
                        ),
                        if (data['paymentLink'] == null)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'A payment link is not available for these dues yet. The reminder includes the balance and contact instructions.',
                            ),
                          ),
                        if (data['paymentLink'] == null &&
                            moneyInt(data['totalDues']) > 0)
                          OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () async {
                                    setState(() => busy = true);
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .post(
                                            '/money/residents/${widget.residentId}/payment-link',
                                            {},
                                          );
                                      ref.invalidate(
                                        moneyObjectProvider(query),
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        showError(context, e);
                                      }
                                    } finally {
                                      if (mounted) setState(() => busy = false);
                                    }
                                  },
                            icon: const Icon(Icons.add_link),
                            label: Text(
                              busy ? 'Creating…' : 'Create Payment Link',
                            ),
                          ),
                        if (moneyInt(data['totalDues']) > 0)
                          OutlinedButton.icon(
                            onPressed: busy ? null : showPaymentQr,
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Generate Payment QR'),
                          ),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed:
                                  widget.action == 'Remind Parent' &&
                                      r['parentPhone'] == null
                                  ? null
                                  : () => moneyWhatsApp(
                                      context,
                                      '${widget.action == 'Remind Parent' ? r['parentPhone'] : r['whatsappNumber'] ?? r['mobile']}',
                                      widget.action == 'Remind Parent'
                                          ? 'Hello ${r['parentName'] ?? 'Parent'}, ${moneyName(r)} has outstanding dues of ${moneyAmount(moneyInt(data['totalDues']))}. ${data['paymentLink'] ?? 'Please contact the property manager.'}'
                                          : '${data['message']}',
                                    ),
                              icon: const Icon(Icons.chat_outlined),
                              label: const Text('WhatsApp'),
                            ),
                            OutlinedButton.icon(
                              onPressed: data['paymentLink'] == null
                                  ? null
                                  : () => SharePlus.instance.share(
                                      ShareParams(
                                        text: '${data['message']}',
                                        sharePositionOrigin: moneyShareOrigin(
                                          context,
                                        ),
                                      ),
                                    ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share Link'),
                            ),
                          ],
                        ),
                      ] else ...[
                        if (widget.action == 'Give Discount') ...[
                          PgField(
                            'Discount Amount (₹)',
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          ListTile(
                            title: const Text('Discount Valid Till'),
                            subtitle: Text(moneyDateText(expiry)),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: expiry,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (d != null) setState(() => expiry = d);
                            },
                          ),
                          moneyChoice(
                            'Discount Valid on Minimum Payment Of',
                            condition,
                            ['FULL', 'CUSTOM'],
                            (v) => setState(() => condition = v),
                          ),
                          if (condition == 'CUSTOM')
                            PgField(
                              'Custom Amount (₹)',
                              controller: minimum,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                        ],
                        PgField(
                          widget.action == 'Add Remarks'
                              ? 'Remarks'
                              : 'Description',
                          controller: description,
                          maxLines: 3,
                        ),
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  if (description.text.trim().isEmpty) {
                                    showError(context, 'Enter a description');
                                    return;
                                  }
                                  final isDiscount =
                                      widget.action == 'Give Discount';
                                  final value = tryParseRupees(amount.text),
                                      min = tryParseRupees(minimum.text);
                                  if (isDiscount &&
                                      (value == null ||
                                          value <= 0 ||
                                          (condition == 'CUSTOM' &&
                                              (min == null || min <= 0)))) {
                                    showError(
                                      context,
                                      'Enter valid discount and minimum amounts',
                                    );
                                    return;
                                  }
                                  setState(() => busy = true);
                                  try {
                                    await ref.read(apiClientProvider).post(
                                      '/money/residents/${widget.residentId}/${isDiscount ? 'discount' : 'remarks'}',
                                      {
                                        'description': description.text.trim(),
                                        if (isDiscount) ...{
                                          'amount': value,
                                          'validTill': moneyDateText(expiry),
                                          'minimumPayment': condition,
                                          if (condition == 'CUSTOM')
                                            'minimumAmount': min,
                                        },
                                      },
                                    );
                                    if (context.mounted) {
                                      refreshMoney(ref);
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      showError(context, e);
                                    }
                                  } finally {
                                    if (mounted) setState(() => busy = false);
                                  }
                                },
                          child: Text(busy ? 'Saving…' : widget.action),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Rect moneyShareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
}
