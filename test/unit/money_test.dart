import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/models/models.dart';

void main() {
  test('backend paise are displayed as rupees', () {
    expect(rupees(500000), '₹5000');
    expect(rupees(32516), '₹325.16');
  });
  test('rupee input converts exactly to paise', () {
    expect(parseRupees('1200.05'), 120005);
    expect(parseRupees('1.2'), 120);
    expect(tryParseRupees('1.234'), isNull);
    expect(tryParseRupees('-1'), isNull);
  });
}
