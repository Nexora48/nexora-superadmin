import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_superadmin/app/data/models/platform_models.dart';

void main() {
  test('LoginStep parses MFA and setup responses', () {
    final a = LoginStep.fromJson({'mfa_required': true, 'mfa_setup_required': false, 'mfa_token': 't'});
    expect(a.mfaRequired, isTrue);
    expect(a.secret, isNull);
    final b = LoginStep.fromJson({'mfa_required': false, 'mfa_setup_required': true, 'mfa_token': 't', 'secret': 'ABC', 'otpauth_url': 'otpauth://totp/x'});
    expect(b.setupRequired, isTrue);
    expect(b.otpauthUrl, startsWith('otpauth://'));
  });

  test('StaffUser role helpers', () {
    final s = StaffUser.fromJson({'id': '1', 'email': 'a@b.c', 'full_name': 'Nexora Super Admin', 'role': 'super_admin'});
    expect(s.isSuper, isTrue);
    expect(s.initials, 'NA');
    expect(StaffUser.fromJson({'id': '2', 'email': 'x@y.z', 'full_name': 'Sam', 'role': 'platform_support'}).isSuper, isFalse);
  });

  test('SocietyDetail parses services, admins and activity', () {
    final d = SocietyDetail.fromJson({
      'id': 's1',
      'name': 'Lakeview',
      'slug': 'lakeview',
      'city': 'Pune',
      'status': 'suspended',
      'created_at': '2026-10-23T10:00:00Z',
      'blocks': 2,
      'flats': 40,
      'residents': 55,
      'enabled_services': 9,
      'total_services': 10,
      'address': '12 Lake Rd',
      'state': 'MH',
      'pincode': '411001',
      'suspended_reason': 'contract ended',
      'admins': [
        {'id': 'u1', 'full_name': 'Meera', 'email': 'm@x.test', 'phone': '9876543210', 'must_change_password': true}
      ],
      'features': [
        {'key': 'visitors', 'name': 'Visitor Management', 'default_enabled': true, 'override': false, 'enabled': false, 'reason': 'unpaid'}
      ],
      'recent_activity': [
        {
          'id': 5,
          'actor_type': 'platform',
          'action': 'feature.toggle',
          'entity': 'society',
          'meta': {
            'reason': 'unpaid',
            'changes': [
              {'feature': 'visitors', 'from': true, 'to': false}
            ]
          },
          'ip': '1.2.3.4',
          'created_at': '2026-10-23T10:05:00Z'
        }
      ],
    });
    expect(d.isSuspended, isTrue);
    expect(d.admins.single.mustChangePassword, isTrue);
    expect(d.features.single.override, isFalse);
    expect(d.features.single.enabled, isFalse);
    expect(d.recent.single.summary, contains('visitors off'));
  });

  test('Credentials without a temporary password means an existing account', () {
    final c = Credentials.fromJson({'user_id': 'u', 'email': 'e@x.test', 'phone': '9999999999', 'existing_account': true});
    expect(c.temporaryPassword, isNull);
    expect(c.existingAccount, isTrue);
  });
}
