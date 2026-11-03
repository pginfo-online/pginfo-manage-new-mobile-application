import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../shared/components/common.dart';

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
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    org.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
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
      ref.invalidate(sessionProvider);
      ref.invalidate(propertiesProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(residentsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(globalSearchProvider);
      ref.invalidate(tenantLedgerProvider);
      ref.invalidate(membersProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: form,
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
                  if (register) ...[
                    PgField(
                      'Your name',
                      controller: name,
                      validator: requiredText,
                    ),
                    PgField(
                      'Organization name',
                      controller: org,
                      validator: requiredText,
                    ),
                  ],
                  PgField(
                    'Email',
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.contains('@') ?? false)
                        ? null
                        : 'Enter a valid email',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: password,
                      obscureText: true,
                      validator: (v) => (v?.length ?? 0) >= 8
                          ? null
                          : 'At least 8 characters',
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
                  TextButton(
                    onPressed: () => setState(() => register = !register),
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
    ),
  );
}
