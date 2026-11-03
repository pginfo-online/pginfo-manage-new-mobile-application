import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/providers.dart';
import '../../core/design_system/theme.dart';

class PgHeader extends ConsumerWidget implements PreferredSizeWidget {
  const PgHeader({super.key, this.title, this.actions = const []});
  final String? title;
  final List<Widget> actions;
  @override
  Size get preferredSize => const Size.fromHeight(62);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = ref.watch(propertiesProvider).asData?.value ?? [];
    final selected = ref.watch(selectedPropertyProvider);
    final name =
        title ??
        props.where((p) => p.id == selected).firstOrNull?.name ??
        'Select property';
    return AppBar(
      toolbarHeight: 62,
      title: title == null
          ? InkWell(
              onTap: () => context.push('/properties/select'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.apartment, color: PgTheme.blue),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            )
          : Text(name),
      actions: actions,
    );
  }
}

class PgCard extends StatelessWidget {
  const PgCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PgAsync<T> extends StatelessWidget {
  const PgAsync({
    super.key,
    required this.value,
    required this.data,
    this.empty = 'Nothing here yet',
    this.retry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final String empty;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (e, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(e.toString(), textAlign: TextAlign.center),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.trailing,
  });
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: trailing,
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.trending_up,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => PgCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PgTheme.blue),
        const SizedBox(height: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class PgField extends StatelessWidget {
  const PgField(
    this.label, {
    super.key,
    this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
String? mobileValidator(String? value) =>
    RegExp(r'^[6-9][0-9]{9}$').hasMatch(value ?? '')
    ? null
    : 'Enter a valid 10-digit mobile number';
void showError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
