import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_superadmin/app/core/widgets/charts.dart';
import 'package:nexora_superadmin/app/data/models/m10_models.dart';
import 'package:nexora_superadmin/app/data/models/platform_models.dart';

void main() {
  test('Plan parses features, limits and the unlimited flag', () {
    final p = Plan.fromJson({
      'id': '1',
      'key': 'starter',
      'name': 'Starter',
      'rate_per_unit_paise': 1000,
      'flat_fee_paise': 0,
      'features': ['visitors', 'sos'],
      'limits': {'max_units': 100.0, 'sms_per_month': 500},
      'status': 'active',
      'societies': 3,
    });
    expect(p.limits['max_units'], 100);
    expect(p.features, ['visitors', 'sos']);
    expect(p.unlimited, isFalse);
    expect(
      Plan.fromJson({
        'id': '2',
        'key': 'legacy',
        'name': 'L',
        'limits': {},
        'features': null,
        'status': 'archived',
      }).unlimited,
      isTrue,
    );
  });

  test('UsageRow ratio and warning flags', () {
    final u = UsageRow.fromJson({
      'key': 'max_units',
      'name': 'Flats',
      'used': 90,
      'max': 100,
      'hard': true,
      'exceeded': false,
      'at_warning': true,
    });
    expect(u.ratio, closeTo(0.9, 0.001));
    final free = UsageRow.fromJson({
      'key': 'x',
      'name': 'X',
      'used': 5,
      'max': null,
      'hard': false,
      'exceeded': false,
      'at_warning': false,
    });
    expect(free.max, isNull);
    expect(free.ratio, 0);
  });

  test('SocietyUsage reads plan, month totals and series', () {
    final s = SocietyUsage.fromJson({
      'plan': {'plan_key': 'standard', 'plan_name': 'Standard', 'usage': []},
      'plan_id': 'abc',
      'differs_from_plan': ['polls'],
      'month_totals': {'visitors': 12},
      'series': {
        'visitors': [
          {'day': '2026-11-01', 'value': 3},
        ],
      },
    });
    expect(s.planName, 'Standard');
    expect(s.differsFromPlan, ['polls']);
    expect(s.monthTotals['visitors'], 12);
    expect(s.series['visitors']!.single.value, 3);
  });

  test('Overview, adoption and alerts parse', () {
    final o = Overview.fromJson({
      'societies': 4,
      'active_societies': 3,
      'dau': 20,
      'mau': 55,
      'mrr_paise': 150000,
      'range_days': 30,
      'series': {
        'active_users': [
          {'day': '2026-11-01', 'value': 1},
        ],
      },
      'top': [
        {'society_id': 's', 'name': 'A', 'value': 9},
      ],
      'unused': [
        {
          'key': 'polls',
          'name': 'Polls',
          'enabled': 3,
          'used': 1,
          'adoption_pc': 33,
          'unused': [
            {'id': 'x', 'name': 'B', 'city': 'Pune', 'units': 10},
          ],
        },
      ],
      'alerts': [
        {
          'kind': 'limit',
          'message': 'A: Flats at the plan limit',
          'society_id': 's',
        },
      ],
    });
    expect(o.mrrPaise, 150000);
    expect(o.unused.single.unused.single.name, 'B');
    expect(o.alerts.single.kind, 'limit');
  });

  test('StaffMember roles and states', () {
    final m = StaffMember.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'full_name': 'A',
      'role': 'platform_support',
      'status': 'disabled',
      'mfa_enabled': false,
      'invite_pending': true,
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(m.isSuper, isFalse);
    expect(m.disabled, isTrue);
    expect(m.invitePending, isTrue);
    expect(m.roleLabel, 'Support (read-only)');
  });

  test('Broadcast audience label and cancel window', () {
    Broadcast b(Map<String, dynamic> aud, String st) => Broadcast.fromJson({
      'id': '1',
      'title': 't',
      'body': 'b',
      'audience': aud,
      'status': st,
      'recipients': 2,
      'sent_count': 0,
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(b({'all': true}, 'queued').audienceLabel, 'All societies');
    expect(
      b({
        'plan_ids': ['a', 'b'],
      }, 'queued').audienceLabel,
      '2 plan(s)',
    );
    expect(
      b({
        'society_ids': ['a'],
      }, 'queued').audienceLabel,
      '1 society(ies)',
    );
    expect(b({'all': true}, 'queued').cancellable, isTrue);
    expect(b({'all': true}, 'sending').cancellable, isFalse);
  });

  test('HealthReport and AppVersion', () {
    final h = HealthReport.fromJson({
      'version': '1.1.0',
      'uptime_seconds': 90,
      'status': 'warn',
      'migration_version': 50,
      'checks': [
        {'name': 'Redis', 'status': 'ok', 'detail': 'reachable'},
      ],
      'sweepers': [
        {'name': 'billing', 'last_run': '2026-11-01T10:00:00Z'},
      ],
    });
    expect(h.checks.single.name, 'Redis');
    expect(h.sweepers.single.name, 'billing');
    expect(
      AppVersion.fromJson({
        'app': 'get',
        'min_version': '1.0.0',
        'latest_version': '1.2.0',
      }).label,
      'Get (guards)',
    );
  });

  test('AuditRow understands the M10 actions', () {
    AuditRow row(String action, Map<String, dynamic> meta) =>
        AuditRow.fromJson({
          'id': 1,
          'actor_type': 'platform',
          'action': action,
          'meta': meta,
          'created_at': '2026-01-01T00:00:00Z',
        });
    expect(
      row('plan.assign', {'from': 'starter', 'to': 'standard'}).summary,
      'Plan changed: starter → standard',
    );
    expect(
      row('staff.invite', {'email': 'x@y.z'}).summary,
      'Staff invited: x@y.z',
    );
    expect(
      row('audit.export', {'rows': 12}).summary,
      'Audit log exported (12 rows)',
    );
    expect(row('something.else', {}).summary, 'Something else');
  });

  test('chart helpers', () {
    expect(compact(950), '950');
    expect(compact(1200), '1.2k');
    expect(compact(25000), '25k');
    expect(compact(3400000), '3.4M');
    expect(shortDay('2026-11-07'), '7 Nov');
  });
}
