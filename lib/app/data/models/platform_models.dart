class StaffUser {
  final String id;
  final String email;
  final String fullName;
  final String role; // super_admin | platform_support

  const StaffUser({required this.id, required this.email, required this.fullName, required this.role});

  factory StaffUser.fromJson(Map<String, dynamic> j) => StaffUser(
        id: '${j['id']}',
        email: '${j['email']}',
        fullName: '${j['full_name']}',
        role: '${j['role']}',
      );

  bool get isSuper => role == 'super_admin';
  String get roleLabel => isSuper ? 'Super admin' : 'Support (read-only)';

  String get initials {
    final p = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }
}

/// Result of sign-in step 1.
class LoginStep {
  final bool mfaRequired;
  final bool setupRequired;
  final String mfaToken;
  final String? secret;
  final String? otpauthUrl;

  const LoginStep({required this.mfaRequired, required this.setupRequired, required this.mfaToken, this.secret, this.otpauthUrl});

  factory LoginStep.fromJson(Map<String, dynamic> j) => LoginStep(
        mfaRequired: j['mfa_required'] == true,
        setupRequired: j['mfa_setup_required'] == true,
        mfaToken: '${j['mfa_token']}',
        secret: j['secret'] as String?,
        otpauthUrl: j['otpauth_url'] as String?,
      );
}

class PlatformSession {
  final String accessToken;
  final String refreshToken;
  final StaffUser user;
  final List<String> recoveryCodes;

  const PlatformSession({required this.accessToken, required this.refreshToken, required this.user, this.recoveryCodes = const []});

  factory PlatformSession.fromJson(Map<String, dynamic> j) => PlatformSession(
        accessToken: '${j['access_token']}',
        refreshToken: '${j['refresh_token']}',
        user: StaffUser.fromJson((j['user'] as Map).cast()),
        recoveryCodes: ((j['recovery_codes'] as List?) ?? []).map((e) => '$e').toList(),
      );
}

class SocietyRow {
  final String id;
  final String name;
  final String slug;
  final String city;
  final String status; // active | trial | suspended
  final DateTime createdAt;
  final int blocks;
  final int flats;
  final int residents;
  final DateTime? lastSignIn;
  final int enabledServices;
  final int totalServices;

  const SocietyRow({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.status,
    required this.createdAt,
    required this.blocks,
    required this.flats,
    required this.residents,
    this.lastSignIn,
    required this.enabledServices,
    required this.totalServices,
  });

  factory SocietyRow.fromJson(Map<String, dynamic> j) => SocietyRow(
        id: '${j['id']}',
        name: '${j['name']}',
        slug: '${j['slug']}',
        city: '${j['city'] ?? ''}',
        status: '${j['status']}',
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
        blocks: (j['blocks'] as num?)?.toInt() ?? 0,
        flats: (j['flats'] as num?)?.toInt() ?? 0,
        residents: (j['residents'] as num?)?.toInt() ?? 0,
        lastSignIn: j['last_sign_in'] == null ? null : DateTime.tryParse('${j['last_sign_in']}'),
        enabledServices: (j['enabled_services'] as num?)?.toInt() ?? 0,
        totalServices: (j['total_services'] as num?)?.toInt() ?? 0,
      );

  bool get isSuspended => status == 'suspended';
}

class AdminRow {
  final String id;
  final String fullName;
  final String? email;
  final String phone;
  final DateTime? lastLoginAt;
  final bool mustChangePassword;

  const AdminRow({required this.id, required this.fullName, this.email, required this.phone, this.lastLoginAt, required this.mustChangePassword});

  factory AdminRow.fromJson(Map<String, dynamic> j) => AdminRow(
        id: '${j['id']}',
        fullName: '${j['full_name']}',
        email: j['email'] as String?,
        phone: '${j['phone']}',
        lastLoginAt: j['last_login_at'] == null ? null : DateTime.tryParse('${j['last_login_at']}'),
        mustChangePassword: j['must_change_password'] == true,
      );
}

class FeatureRow {
  final String key;
  final String name;
  final String description;
  final bool defaultEnabled;
  final bool? override;
  final bool enabled;
  final DateTime? updatedAt;
  final String reason;

  const FeatureRow({
    required this.key,
    required this.name,
    required this.description,
    required this.defaultEnabled,
    this.override,
    required this.enabled,
    this.updatedAt,
    this.reason = '',
  });

  factory FeatureRow.fromJson(Map<String, dynamic> j) => FeatureRow(
        key: '${j['key']}',
        name: '${j['name']}',
        description: '${j['description'] ?? ''}',
        defaultEnabled: j['default_enabled'] == true,
        override: j['override'] as bool?,
        enabled: j['enabled'] == true,
        updatedAt: j['updated_at'] == null ? null : DateTime.tryParse('${j['updated_at']}'),
        reason: '${j['reason'] ?? ''}',
      );
}

class AuditRow {
  final int id;
  final String actorType;
  final String? actorName;
  final String? actorEmail;
  final String? actorRole;
  final String? societyId;
  final String? societyName;
  final String action;
  final String entity;
  final String entityId;
  final Map<String, dynamic> meta;
  final String ip;
  final DateTime createdAt;

  const AuditRow({
    required this.id,
    required this.actorType,
    this.actorName,
    this.actorEmail,
    this.actorRole,
    this.societyId,
    this.societyName,
    required this.action,
    required this.entity,
    this.entityId = '',
    required this.meta,
    required this.ip,
    required this.createdAt,
  });

  factory AuditRow.fromJson(Map<String, dynamic> j) => AuditRow(
        id: (j['id'] as num).toInt(),
        actorType: '${j['actor_type']}',
        actorName: j['actor_name'] as String?,
        actorEmail: j['actor_email'] as String?,
        actorRole: j['actor_role'] as String?,
        societyId: j['society_id'] as String?,
        societyName: j['society_name'] as String?,
        action: '${j['action']}',
        entity: '${j['entity'] ?? ''}',
        entityId: '${j['entity_id'] ?? ''}',
        meta: ((j['meta'] as Map?) ?? const {}).cast<String, dynamic>(),
        ip: '${j['ip'] ?? ''}',
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
      );

  /// Short human sentence for the activity feed.
  String get summary {
    switch (action) {
      case 'society.create':
        return 'Society onboarded';
      case 'society.update':
        return 'Society details edited';
      case 'society.suspend':
        return 'Society suspended: ${meta['reason'] ?? ''}';
      case 'society.reactivate':
        return 'Society reactivated';
      case 'admin.create':
        return 'Admin added: ${meta['email'] ?? ''}';
      case 'admin.reset_password':
        return 'Admin password reset';
      case 'feature.toggle':
        final ch = ((meta['changes'] as List?) ?? []).map((e) {
          final m = (e as Map);
          return '${m['feature']} ${m['to'] == true ? 'on' : 'off'}';
        }).join(', ');
        return 'Services changed: $ch (${meta['reason'] ?? ''})';
      case 'auth.login':
        return 'Signed in (${meta['method'] ?? ''})';
      case 'auth.change_password':
        return 'Password changed';
      case 'auth.login_failed':
        return 'Failed sign-in';
      case 'auth.logout':
        return 'Signed out';
      case 'resident.create':
        return 'Resident added';
      case 'block.create':
        return 'Block added';
      case 'unit.bulk_create':
        return 'Flats generated';
      case 'platform.login':
        return 'Staff signed in';
      case 'platform.logout':
        return 'Staff signed out';
      case 'platform.mfa_enrolled':
        return 'Authenticator enrolled';
      case 'platform.login_failed':
        return 'Failed staff sign-in';
      case 'platform.mfa_failed':
        return 'Failed 2FA code';
      case 'plan.create':
        return 'Plan created: ${((meta['after'] as Map?) ?? const {})['name'] ?? ''}';
      case 'plan.update':
        return 'Plan edited: ${((meta['after'] as Map?) ?? const {})['name'] ?? ''}';
      case 'plan.archive':
        return 'Plan archived: ${meta['key'] ?? ''}';
      case 'plan.assign':
        return 'Plan changed: ${meta['from'] ?? 'none'} → ${meta['to'] ?? ''}';
      case 'staff.invite':
        return 'Staff invited: ${meta['email'] ?? ''}';
      case 'staff.reinvite':
        return 'Invitation re-issued: ${meta['email'] ?? ''}';
      case 'staff.update':
        return 'Staff access changed';
      case 'staff.reset_mfa':
        return 'Authenticator reset';
      case 'broadcast.create':
        return 'Broadcast sent: ${meta['title'] ?? ''}';
      case 'broadcast.cancel':
        return 'Broadcast cancelled';
      case 'app_version.set':
        return 'App version rules changed: $entityId';
      case 'audit.export':
        return 'Audit log exported (${meta['rows'] ?? 0} rows)';
      case 'audit.retention':
        return 'Audit retention changed to ${meta['after'] ?? ''} days';
      case 'audit.purge':
        return 'Old audit entries removed (${meta['removed'] ?? 0})';
      case 'subscription.set':
        return 'Subscription changed';
      default:
        // "payment.record" → "Payment record"
        final t = action.replaceAll('.', ' ').replaceAll('_', ' ');
        return t.isEmpty ? action : '${t[0].toUpperCase()}${t.substring(1)}';
    }
  }
}

class CatalogueRow {
  final String key;
  final String name;
  final String description;
  final bool defaultEnabled;

  const CatalogueRow({required this.key, required this.name, required this.description, required this.defaultEnabled});

  factory CatalogueRow.fromJson(Map<String, dynamic> j) => CatalogueRow(
        key: '${j['key']}',
        name: '${j['name']}',
        description: '${j['description'] ?? ''}',
        defaultEnabled: j['default_enabled'] == true,
      );
}

class Credentials {
  final String userId;
  final String email;
  final String phone;
  final String? temporaryPassword;
  final bool existingAccount;

  const Credentials({required this.userId, required this.email, required this.phone, this.temporaryPassword, required this.existingAccount});

  factory Credentials.fromJson(Map<String, dynamic> j) => Credentials(
        userId: '${j['user_id']}',
        email: '${j['email']}',
        phone: '${j['phone']}',
        temporaryPassword: j['temporary_password'] as String?,
        existingAccount: j['existing_account'] == true,
      );
}

class SocietyDetail extends SocietyRow {
  final String address;
  final String state;
  final String pincode;
  final String? suspendedReason;
  final DateTime? suspendedAt;
  final List<AdminRow> admins;
  final List<FeatureRow> features;
  final List<AuditRow> recent;

  const SocietyDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.city,
    required super.status,
    required super.createdAt,
    required super.blocks,
    required super.flats,
    required super.residents,
    super.lastSignIn,
    required super.enabledServices,
    required super.totalServices,
    required this.address,
    required this.state,
    required this.pincode,
    this.suspendedReason,
    this.suspendedAt,
    this.admins = const [],
    this.features = const [],
    this.recent = const [],
  });

  factory SocietyDetail.fromJson(Map<String, dynamic> j) {
    final b = SocietyRow.fromJson(j);
    return SocietyDetail(
      id: b.id,
      name: b.name,
      slug: b.slug,
      city: b.city,
      status: b.status,
      createdAt: b.createdAt,
      blocks: b.blocks,
      flats: b.flats,
      residents: b.residents,
      lastSignIn: b.lastSignIn,
      enabledServices: b.enabledServices,
      totalServices: b.totalServices,
      address: '${j['address'] ?? ''}',
      state: '${j['state'] ?? ''}',
      pincode: '${j['pincode'] ?? ''}',
      suspendedReason: j['suspended_reason'] as String?,
      suspendedAt: j['suspended_at'] == null ? null : DateTime.tryParse('${j['suspended_at']}'),
      admins: ((j['admins'] as List?) ?? []).map((e) => AdminRow.fromJson((e as Map).cast())).toList(),
      features: ((j['features'] as List?) ?? []).map((e) => FeatureRow.fromJson((e as Map).cast())).toList(),
      recent: ((j['recent_activity'] as List?) ?? []).map((e) => AuditRow.fromJson((e as Map).cast())).toList(),
    );
  }
}

class PlatformStats {
  final int societies;
  final int active;
  final int trial;
  final int suspended;
  final int flats;
  final int residents;
  final int admins;

  const PlatformStats({
    required this.societies,
    required this.active,
    required this.trial,
    required this.suspended,
    required this.flats,
    required this.residents,
    required this.admins,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> j) => PlatformStats(
        societies: (j['societies'] as num?)?.toInt() ?? 0,
        active: (j['active'] as num?)?.toInt() ?? 0,
        trial: (j['trial'] as num?)?.toInt() ?? 0,
        suspended: (j['suspended'] as num?)?.toInt() ?? 0,
        flats: (j['flats'] as num?)?.toInt() ?? 0,
        residents: (j['residents'] as num?)?.toInt() ?? 0,
        admins: (j['admins'] as num?)?.toInt() ?? 0,
      );
}
