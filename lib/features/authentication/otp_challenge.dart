enum OtpPurpose {
  login('LOGIN'),
  register('REGISTER');

  const OtpPurpose(this.apiValue);
  final String apiValue;
}

class OtpChallenge {
  const OtpChallenge({
    required this.mobile,
    required this.maskedMobile,
    required this.expiresIn,
    required this.resendAfter,
  });

  factory OtpChallenge.fromResponse(
    Object? response,
    String requestedMobile,
    OtpPurpose purpose,
  ) {
    if (response is Map<String, dynamic> &&
        response['success'] == true &&
        response['purpose'] == purpose.apiValue &&
        response['mobile'] == requestedMobile &&
        response['maskedMobile'] is String &&
        response['expiresInSeconds'] is int &&
        response['resendAfterSeconds'] is int) {
      final expires = response['expiresInSeconds'] as int;
      final resend = response['resendAfterSeconds'] as int;
      if (expires >= 0 && resend >= 0) {
        return OtpChallenge(
          mobile: requestedMobile,
          maskedMobile: response['maskedMobile'] as String,
          expiresIn: Duration(seconds: expires),
          resendAfter: Duration(seconds: resend),
        );
      }
    }
    throw const FormatException('Unexpected verification response');
  }

  final String mobile;
  final String maskedMobile;
  final Duration expiresIn;
  final Duration resendAfter;
}

String? normalizeIndianPhone(String raw) {
  final input = raw.trim();
  if (!RegExp(r'^\+?[\d().\s-]+$').hasMatch(input)) return null;
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (!input.startsWith('+') &&
      digits.length == 11 &&
      digits.startsWith('0')) {
    digits = digits.substring(1);
  } else if (input.startsWith('+')) {
    return null;
  }
  return RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? digits : null;
}
