import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';
import '../otp_challenge.dart';
import 'phone_otp_form.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      org = TextEditingController();
  bool register = false, busy = false;
  bool useOtp = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    org.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || form.currentState?.validate() != true) return;
    setState(() => busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (register) {
        await auth.register(
          email.text.trim(),
          password.text,
          name.text.trim(),
          org.text.trim(),
        );
      } else {
        await auth.login(email.text.trim(), password.text);
      }
      await _finishAuthentication();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _finishAuthentication() async {
    if (!mounted) return;
    ref.invalidate(sessionProvider);
    await ref.read(sessionProvider.future);
    if (!mounted) return;
    ref.invalidate(propertiesProvider);
    ref.invalidate(roomsProvider);
    ref.invalidate(residentsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(globalSearchProvider);
    ref.invalidate(tenantLedgerProvider);
    ref.invalidate(membersProvider);
    context.go('/home');
  }

  String? validateLoginId(String? value) {
    final identifier = value?.trim() ?? '';
    if (identifier.contains('@')) return null;
    if (register) return 'Enter a valid email';
    return normalizeIndianPhone(identifier) == null
        ? 'Enter your email or Indian mobile number'
        : null;
  }

  Widget _passwordForm() => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (register) ...[
          PgField('Your name', controller: name, validator: requiredText),
          PgField(
            'Organization name',
            controller: org,
            validator: requiredText,
          ),
        ],
        PgField(
          register ? 'Email' : 'Email or mobile number',
          controller: email,
          keyboardType: TextInputType.emailAddress,
          validator: validateLoginId,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: password,
            obscureText: true,
            validator: (v) =>
                (v?.length ?? 0) >= 8 ? null : 'At least 8 characters',
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Please wait…'
                : register
                ? 'Create account'
                : 'Sign in',
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 64,
                  color: Color(0xff3156f5),
                ),
                const SizedBox(height: 16),
                Text(
                  register ? 'Create your workspace' : 'Welcome to PgInfo',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Password')),
                    ButtonSegment(value: true, label: Text('SMS code')),
                  ],
                  selected: {useOtp},
                  showSelectedIcon: false,
                  onSelectionChanged: busy
                      ? null
                      : (selection) =>
                            setState(() => useOtp = selection.single),
                ),
                const SizedBox(height: 20),
                if (useOtp)
                  PhoneOtpForm(
                    key: ValueKey(register),
                    purpose: register ? OtpPurpose.register : OtpPurpose.login,
                    onBusyChanged: (value) => setState(() => busy = value),
                    onAuthenticated: _finishAuthentication,
                  )
                else
                  _passwordForm(),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => register = !register),
                  child: Text(
                    register
                        ? 'Already have an account? Sign in'
                        : 'New to PgInfo? Create account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
