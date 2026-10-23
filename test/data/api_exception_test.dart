import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_superadmin/app/data/providers/api_exception.dart';

void main() {
  test('ApiException flags', () {
    const e = ApiException(statusCode: 403, code: 'FEATURE_DISABLED', message: 'x');
    expect(e.isFeatureDisabled, isTrue);
    expect(e.isUnauthorized, isFalse);
  });
}
