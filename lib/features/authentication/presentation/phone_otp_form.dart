import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/network/api_client.dart';
import '../otp_challenge.dart';

class PhoneOtpForm extends ConsumerStatefulWidget {
  const PhoneOtpForm({
    super.key,
    required this.purpose,
    required this.onBusyChanged,
    required this.onAuthenticated,
  });

  final OtpPurpose purpose;
  final ValueChanged<bool> onBusyChanged;
  final Future<void> Function() onAuthenticated;

  @override
  ConsumerState<PhoneOtpForm> createState() => _PhoneOtpFormState();
}

class _PhoneOtpFormState extends ConsumerState<PhoneOtpForm> {
  static const _phoneHint = MethodChannel(
    'com.pginfo.manage/phone_number_hint',
  );

  final _form = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _organization = TextEditingController();

  Timer? _timer;
  OtpChallenge? _challenge;
  DateTime? _expiresAt;
  DateTime? _resendAt;
  DateTime? _verifyAt;
  String? _error;
  String? _phoneHintMessage;
  bool _busy = false;
  bool _requestingHint = false;

  bool get _register => widget.purpose == OtpPurpose.register;
  bool get _canSuggestPhone =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _hasCountdown => [
    _expiresAt,
    _resendAt,
    _verifyAt,
  ].any((deadline) => _remaining(deadline) > 0);

  int _remaining(DateTime? deadline) {
    final milliseconds =
        deadline?.difference(DateTime.now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobile.dispose();
    _code.dispose();
    _name.dispose();
    _organization.dispose();
    super.dispose();
  }

  void _updateCountdown() {
    _timer?.cancel();
    if (!_hasCountdown) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (!_hasCountdown) timer.cancel();
    });
  }

  Future<void> _suggestPhoneNumber() async {
    if (_requestingHint || _busy) return;
    final previous = _mobile.text;
    setState(() {
      _requestingHint = true;
      _phoneHintMessage = null;
    });
    String? number;
    try {
      final hint = await _phoneHint.invokeMethod<String>('requestPhoneNumber');
      if (hint != null) number = normalizeIndianPhone(hint);
    } on PlatformException {
      // The manual field and platform autofill remain available.
    } on MissingPluginException {
      // Some Android devices do not have a phone-number hint service.
    }
    if (!mounted) return;
    setState(() {
      _requestingHint = false;
      if (_mobile.text != previous) return;
      if (number != null) {
        _mobile.value = TextEditingValue(
          text: number,
          selection: TextSelection.collapsed(offset: number.length),
        );
      } else if (_mobile.text.isEmpty) {
        _phoneHintMessage = 'Enter your mobile number to continue.';
      }
    });
  }

  Future<void> _requestCode({required bool resend}) async {
    if (_busy || _remaining(_resendAt) > 0) return;
    if (!resend && _form.currentState?.validate() != true) return;
    final mobile = resend
        ? _challenge?.mobile
        : normalizeIndianPhone(_mobile.text);
    if (mobile == null) return;
    FocusScope.of(context).unfocus();

    await _runRequest(() async {
      final challenge = await ref
          .read(authRepositoryProvider)
          .requestOtp(mobile, widget.purpose, resend: resend);
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _challenge = challenge;
        _expiresAt = now.add(challenge.expiresIn);
        _resendAt = now.add(challenge.resendAfter);
        _verifyAt = null;
        _code.clear();
      });
      _updateCountdown();
    });
  }

  Future<void> _verifyCode() async {
    final challenge = _challenge;
    if (_busy ||
        challenge == null ||
        _remaining(_verifyAt) > 0 ||
        _remaining(_expiresAt) == 0 ||
        _form.currentState?.validate() != true) {
      return;
    }
    final code = _code.text;
    FocusScope.of(context).unfocus();

    await _runRequest(() async {
      final auth = ref.read(authRepositoryProvider);
      if (_register) {
        final parts = _name.text.trim().split(RegExp(r'\s+'));
        await auth.registerWithOtp(
          mobile: challenge.mobile,
          otp: code,
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.skip(1).join(' ') : null,
          organizationName: _organization.text.trim(),
        );
      } else {
        await auth.loginWithOtp(challenge.mobile, code);
      }
      if (mounted) {
        TextInput.finishAutofillContext(shouldSave: false);
        await widget.onAuthenticated();
      }
    }, verifying: true);
  }

  Future<void> _runRequest(
    Future<void> Function() request, {
    bool verifying = false,
  }) async {
    widget.onBusyChanged(true);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await request();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      final exhausted = failure.code == 'OTP_ATTEMPTS_EXCEEDED';
      final stale =
          exhausted ||
          failure.code == 'OTP_EXPIRED' ||
          failure.code == 'OTP_UNAVAILABLE' ||
          (failure.code == 'UNAUTHORIZED' &&
              failure.message.contains('request a new code'));
      setState(() {
        if (failure.status == 429 && !exhausted) {
          final retryAt = DateTime.now().add(
            failure.retryAfter ?? const Duration(seconds: 30),
          );
          if (verifying) {
            _verifyAt = retryAt;
          } else {
            final previous = _resendAt;
            if (previous == null || retryAt.isAfter(previous)) {
              _resendAt = retryAt;
            }
          }
        }
        if (verifying && (stale || failure.status == 401)) _code.clear();
        if (verifying && stale) _expiresAt = DateTime.now();
        _error = failure.status == 503 || failure.status == 502
            ? 'SMS verification is temporarily unavailable. Try again or use a password.'
            : failure.status == 404
            ? 'No account uses this mobile number. Create an account to continue.'
            : failure.message;
      });
      _updateCountdown();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to complete verification. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  void _changeNumber() {
    _timer?.cancel();
    TextInput.finishAutofillContext(shouldSave: false);
    setState(() {
      _challenge = null;
      _expiresAt = null;
      _resendAt = null;
      _verifyAt = null;
      _error = null;
      _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    final expirySeconds = _remaining(_expiresAt);
    final resendSeconds = _remaining(_resendAt);
    final verifySeconds = _remaining(_verifyAt);
    final minutes = (expirySeconds ~/ 60).toString();
    final seconds = (expirySeconds % 60).toString().padLeft(2, '0');

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (challenge == null) ...[
              if (_register) ...[
                _registrationField('Your name', _name, min: 1),
                _registrationField('Organization name', _organization, min: 2),
              ],
              TextFormField(
                controller: _mobile,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '+91 or 10-digit number',
                ),
                validator: (value) => normalizeIndianPhone(value ?? '') == null
                    ? 'Enter a valid 10-digit Indian mobile number'
                    : null,
              ),
              if (_canSuggestPhone)
                TextButton.icon(
                  onPressed: _busy || _requestingHint
                      ? null
                      : _suggestPhoneNumber,
                  icon: const Icon(Icons.sim_card_outlined),
                  label: const Text('Use a number from this device'),
                ),
              if (_phoneHintMessage case final message?) Text(message),
              const SizedBox(height: 12),
            ] else ...[
              Text('Code sent to +91 ${challenge.maskedMobile}'),
              TextButton(
                onPressed: _busy ? null : _changeNumber,
                child: const Text('Change mobile number'),
              ),
              TextFormField(
                controller: _code,
                enabled: !_busy && expirySeconds > 0,
                autofocus: expirySeconds > 0,
                autofillHints: const [AutofillHints.oneTimeCode],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                enableSuggestions: false,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(labelText: '4-digit code'),
                validator: (value) =>
                    (value?.length ?? 0) == 4 ? null : 'Enter the 4-digit code',
                onFieldSubmitted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 8),
              Text(
                expirySeconds > 0
                    ? 'Expires in $minutes:$seconds'
                    : 'Code expired',
              ),
              const SizedBox(height: 12),
            ],
            if (_error case final message?) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (challenge == null)
              FilledButton(
                onPressed: _busy || _requestingHint || resendSeconds > 0
                    ? null
                    : () => _requestCode(resend: false),
                child: Text(
                  _busy
                      ? 'Sending code…'
                      : resendSeconds > 0
                      ? 'Try again in ${resendSeconds}s'
                      : 'Send code',
                ),
              )
            else ...[
              FilledButton(
                onPressed: _busy || expirySeconds == 0 || verifySeconds > 0
                    ? null
                    : _verifyCode,
                child: Text(
                  _busy
                      ? 'Please wait…'
                      : verifySeconds > 0
                      ? 'Try again in ${verifySeconds}s'
                      : _register
                      ? 'Verify and create account'
                      : 'Verify and sign in',
                ),
              ),
              TextButton(
                onPressed: _busy || resendSeconds > 0
                    ? null
                    : () => _requestCode(resend: true),
                child: Text(
                  resendSeconds > 0
                      ? 'Resend in ${resendSeconds}s'
                      : 'Resend code',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _registrationField(
    String label,
    TextEditingController controller, {
    required int min,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final length = value?.trim().length ?? 0;
        if (length < min) {
          return min == 1 ? 'Enter your name' : 'Enter at least 2 characters';
        }
        return length > 100 ? 'Enter 100 characters or fewer' : null;
      },
    ),
  );
}
