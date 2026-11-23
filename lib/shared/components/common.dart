import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/providers.dart';
import '../../core/design_system/theme.dart';

class PgLogo extends StatelessWidget {
  const PgLogo({super.key, this.size = 38});
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      'ui/ref.png',
      width: size,
      height: size,
      semanticLabel: 'PgInfo',
      cacheWidth: (size * 3).round(),
    ),
  );
}

class PgHeader extends ConsumerWidget implements PreferredSizeWidget {
  const PgHeader({
    super.key,
    this.title,
    this.actions = const [],
    this.bottom,
    this.showProperty = false,
  });
  final String? title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool showProperty;

  @override
  Size get preferredSize =>
      Size.fromHeight(62 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final propertyHeader = title == null || showProperty;
    final properties = propertyHeader
        ? ref.watch(propertiesProvider).value
        : null;
    final selected = propertyHeader
        ? ref.watch(selectedPropertyProvider)
        : null;
    final name = properties?.where((p) => p.id == selected).firstOrNull?.name;
    final foreground = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : Colors.white;
    return AppBar(
      toolbarHeight: 62,
      centerTitle: false,
      backgroundColor: theme.brightness == Brightness.dark
          ? PgTheme.darkHeader
          : PgTheme.blue,
      foregroundColor: foreground,
      scrolledUnderElevation: 0,
      title: propertyHeader
          ? Row(
              children: [
                const PgLogo(),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: foreground),
                    onPressed: () => context.push('/properties/select'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name ?? 'Select property',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Text(title!),
      actions: actions,
      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: bottom!.preferredSize,
              child: TabBarTheme(
                data: TabBarThemeData(
                  labelColor: foreground,
                  unselectedLabelColor: foreground.withValues(alpha: .82),
                  indicatorColor: foreground,
                  dividerColor: foreground.withValues(alpha: .18),
                ),
                child: bottom!,
              ),
            ),
    );
  }
}

class PgSkeleton extends StatelessWidget {
  const PgSkeleton({super.key, required this.height, this.width});
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: PgTheme.skeletonBase(context),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
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
    this.placeholder,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final String empty;
  final VoidCallback? retry;
  final Widget? placeholder;
  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () =>
        placeholder ??
        const Center(
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
    this.autofocus = false,
  });
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => TextField(
    autofocus: autofocus,
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
