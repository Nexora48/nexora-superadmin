import 'package:nexora_superadmin/app/core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/platform_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/society_detail_controller.dart';

class SocietyDetailView extends GetView<SocietyDetailController> {
  const SocietyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    // ── Shared dialog pieces ────────────────────────────────────────────────
    dialogErr() => Obx(() => errorLine(controller.dialogError.value));

    infoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label, style: context.appText.timestamp)),
            Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    // a dialog on the shared frame
    dlg({required String title, String? subtitle, required IconData icon, Color color = AppColors.primary, required Widget body, required List<Widget> actions, double maxWidth = 440, bool dismissible = true}) {
      Get.dialog(
        dialogShell(context, title: title, subtitle: subtitle, icon: icon, color: color, maxWidth: maxWidth, body: body, actions: actions),
        barrierDismissible: dismissible,
      );
    }

    // the primary dialog button: spinner while busy, closes the dialog when [run] says it worked
    primary(String label, IconData icon, Future<bool> Function() run, {Color? color}) {
      return Obx(() => FilledButton.icon(
            style: color == null ? null : FilledButton.styleFrom(backgroundColor: color),
            onPressed: controller.dialogBusy.value
                ? null
                : () async {
                    if (await run()) Get.back();
                  },
            icon: controller.dialogBusy.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : Icon(icon, size: 18),
            label: Text(label),
          ));
    }

    // ── One-time credentials dialog ─────────────────────────────────────────
    credentialsDialog(Credentials c, {String title = 'Admin credentials'}) {
      dlg(
        title: title,
        subtitle: 'Share these with the society admin',
        icon: Icons.vpn_key_rounded,
        color: AppColors.orange,
        dismissible: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            infoRow('Email', c.email),
            infoRow('Mobile', c.phone),
            if (c.temporaryPassword != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(c.temporaryPassword!, style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Clipboard.setData(ClipboardData(text: c.temporaryPassword!)),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Shown only once. Share it securely; the admin must set a new password at first sign-in.', style: context.appText.timestamp),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('This person already has an account and signs in with their existing password.', style: context.appText.timestamp),
              ),
          ],
        ),
        actions: [FilledButton(onPressed: Get.back, child: const Text('Done'))],
      );
    }

    // ── Reason dialog (suspend / services) ──────────────────────────────────
    reasonDialog({required String title, required String message, required String confirm, required Future<bool> Function() onConfirm, bool danger = false}) {
      controller.resetDialog();
      dlg(
        title: title,
        icon: danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
        color: danger ? AppColors.error : AppColors.primary,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: controller.reasonCtrl,
              autofocus: true,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Reason (saved in the audit log)', prefixIcon: Icon(Icons.notes_rounded, size: 20)),
            ),
            dialogErr(),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          primary(confirm, danger ? Icons.block_rounded : Icons.check_rounded, onConfirm, color: danger ? AppColors.error : null),
        ],
      );
    }

    confirmDialog({required String title, required String message, required String confirm, required Future<bool> Function() onConfirm}) {
      controller.resetDialog();
      dlg(
        title: title,
        icon: Icons.help_outline_rounded,
        body: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(message, style: const TextStyle(fontSize: 14, height: 1.4)), dialogErr()]),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          primary(confirm, Icons.check_rounded, onConfirm),
        ],
      );
    }

    // ── Edit profile dialog ─────────────────────────────────────────────────
    editDialog() {
      controller.openEdit();
      dlg(
        title: 'Edit society',
        subtitle: 'Name and address shown to the society',
        icon: Icons.edit_rounded,
        maxWidth: 480,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(controller: controller.nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.apartment_rounded, size: 20))),
            TextField(controller: controller.addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.place_outlined, size: 20))),
            Row(spacing: 12, children: [
              Expanded(child: TextField(controller: controller.cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
              Expanded(child: TextField(controller: controller.stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
            ]),
            TextField(
              controller: controller.pincodeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined, size: 20)),
            ),
            dialogErr(),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          primary('Save', Icons.check_rounded, controller.saveEdit),
        ],
      );
    }

    // ── Add admin dialog ────────────────────────────────────────────────────
    addAdminDialog() {
      controller.openAddAdmin();
      dlg(
        title: 'Add society admin',
        subtitle: 'They get a temporary password to sign in',
        icon: Icons.person_add_alt_1_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(controller: controller.adminNameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded, size: 20))),
            TextField(controller: controller.adminEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (used to sign in)', prefixIcon: Icon(Icons.mail_outline_rounded, size: 20))),
            TextField(
              controller: controller.adminPhoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91  ', prefixIcon: Icon(Icons.phone_outlined, size: 20), counterText: ''),
            ),
            dialogErr(),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          Obx(() => FilledButton.icon(
                onPressed: controller.dialogBusy.value
                    ? null
                    : () async {
                        final c = await controller.addAdmin();
                        if (c != null) {
                          Get.back();
                          credentialsDialog(c, title: 'Admin added');
                        }
                      },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add admin'),
              )),
        ],
      );
    }

    // ── Header: banner card with avatar, name, status and actions ───────────
    headerView(SocietyDetail d) {
      final dim = d.isSuspended;
      final accent = switch (d.status) {
        'active' => AppColors.success,
        'trial' => AppColors.primary,
        'suspended' => AppColors.error,
        _ => AppColors.textSecondaryLight,
      };
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withAlpha(34), AppColors.surfaceLight]),
          border: Border.all(color: accent.withAlpha(60)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.filledTonal(onPressed: Get.back, icon: const Icon(Icons.arrow_back_rounded)),
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: dim ? [AppColors.error.withAlpha(200), AppColors.error] : [AppColors.primaryLight, AppColors.primary]),
                boxShadow: [BoxShadow(color: (dim ? AppColors.error : AppColors.primary).withAlpha(80), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: Text(d.name.isEmpty ? '?' : d.name[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.white)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(d.name, style: context.appText.sectionHeader.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
                  statusChip(d.status),
                ]),
                Wrap(spacing: 14, runSpacing: 4, children: [
                  MetaItem(Icons.tag_rounded, d.slug),
                  if (d.city.isNotEmpty) MetaItem(Icons.place_outlined, d.city),
                  MetaItem(Icons.event_outlined, 'Onboarded ${formatDate(d.createdAt)}'),
                ]),
              ],
            ),
            if (canEdit)
              Wrap(spacing: 10, children: [
                OutlinedButton.icon(onPressed: editDialog, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
                if (d.isSuspended)
                  FilledButton.icon(
                    onPressed: () => confirmDialog(
                      title: 'Reactivate ${d.name}?',
                      message: 'Admins and residents can sign in again.',
                      confirm: 'Reactivate',
                      onConfirm: controller.reactivate,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Reactivate'),
                  )
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => reasonDialog(
                      title: 'Suspend ${d.name}?',
                      message: 'Nobody in this society can sign in and every session ends immediately. Data is kept.',
                      confirm: 'Suspend society',
                      onConfirm: controller.suspend,
                      danger: true,
                    ),
                    icon: const Icon(Icons.pause_rounded, size: 18),
                    label: const Text('Suspend'),
                  ),
              ]),
          ],
        ),
      );
    }

    // ── Tabs ────────────────────────────────────────────────────────────────
    tabBar() {
      const labels = ['Overview', 'Services', 'Admins', 'Activity', 'Usage'];
      return Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Segmented(items: labels, selected: controller.tab.value, onTap: controller.selectTab),
          ));
    }

    // a section title with an icon tile
    sectionTitle(IconData icon, Color color, String title, {String? subtitle}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(spacing: 12, children: [
          IconTile(icon, color, size: 36),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.appText.sectionHeader),
              if (subtitle != null) Text(subtitle, style: context.appText.timestamp),
            ]),
          ),
        ]),
      );
    }

    // ── Overview ────────────────────────────────────────────────────────────
    overviewTab(SocietyDetail d) {
      kpi(IconData icon, Color color, String label, String value, {double? ratio}) => SizedBox(
            width: 215,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.dividerLight),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Row(spacing: 12, children: [
                    IconTile(icon, color),
                    Expanded(child: Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1))),
                  ]),
                  Text(label, style: context.appText.timestamp),
                  if (ratio != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(minHeight: 6, value: ratio, backgroundColor: AppColors.dividerLight, valueColor: AlwaysStoppedAnimation(color)),
                    ),
                ],
              ),
            ),
          );

      // one labelled detail with an icon tile
      detail(IconData icon, String label, String value) => SizedBox(
            width: 300,
            child: Row(spacing: 12, children: [
              IconTile(icon, AppColors.primary, size: 36),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: context.appText.timestamp),
                  Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          );

      final servicesRatio = d.totalServices == 0 ? 0.0 : d.enabledServices / d.totalServices;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 14, runSpacing: 14, children: [
            kpi(Icons.domain_rounded, AppColors.primary, 'Blocks', '${d.blocks}'),
            kpi(Icons.meeting_room_outlined, AppColors.teal, 'Flats', '${d.flats}'),
            kpi(Icons.people_outline_rounded, AppColors.purple, 'Residents', '${d.residents}'),
            kpi(Icons.extension_outlined, AppColors.orange, 'Services on', '${d.enabledServices}/${d.totalServices}', ratio: servicesRatio),
          ]),
          const SizedBox(height: 20),
          cardBox(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle(Icons.info_outline_rounded, AppColors.primary, 'Society details'),
                Wrap(spacing: 24, runSpacing: 18, children: [
                  detail(Icons.place_outlined, 'Address', d.address),
                  detail(Icons.location_city_rounded, 'City / State', [d.city, d.state].where((e) => e.isNotEmpty).join(', ')),
                  detail(Icons.pin_drop_outlined, 'Pincode', d.pincode),
                  detail(Icons.event_available_rounded, 'Onboarded', formatDate(d.createdAt)),
                  detail(Icons.login_rounded, 'Last sign-in', d.lastSignIn == null ? 'never' : '${timeAgo(d.lastSignIn)} (${formatDateTime(d.lastSignIn)})'),
                ]),
              ],
            ),
          ),
        ],
      );
    }

    // ── Services ────────────────────────────────────────────────────────────
    serviceRow(SocietyDetail d, FeatureRow f) {
      final overridden = f.override != null && f.override != f.defaultEnabled;
      final color = f.enabled ? AppColors.primary : AppColors.textSecondaryLight;
      return SoftCard(
        accent: f.enabled ? AppColors.primary : null,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconTile(Icons.extension_outlined, color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(f.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      if (overridden) const PillTag('Overridden', AppColors.orange),
                    ]),
                    Text(
                      overridden && f.reason.isNotEmpty ? '${f.reason} · ${timeAgo(f.updatedAt)}' : (f.description.isEmpty ? f.key : f.description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appText.timestamp,
                    ),
                  ],
                ),
              ),
              Switch(
                value: f.enabled,
                onChanged: !canEdit
                    ? null
                    : (v) => reasonDialog(
                          title: '${v ? 'Turn on' : 'Turn off'} ${f.name} for ${d.name}?',
                          message: v
                              ? 'Residents and admins of this society get this service again.'
                              : 'This service is hidden and blocked for this society right away. Its data is kept.',
                          confirm: v ? 'Turn on' : 'Turn off',
                          danger: !v,
                          onConfirm: () => controller.setFeature(f, v),
                        ),
              ),
            ],
          ),
        ),
      );
    }

    servicesTab(SocietyDetail d) {
      final ratio = d.totalServices == 0 ? 0.0 : d.enabledServices / d.totalServices;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Row(spacing: 12, children: [
                  const IconTile(Icons.toggle_on_outlined, AppColors.primary, size: 38),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${d.enabledServices} of ${d.totalServices} services are on', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('Changes apply to the API immediately; apps refresh within 5 minutes.', style: context.appText.timestamp),
                    ]),
                  ),
                  if (canEdit) ...[
                    FilledButton.tonalIcon(
                      onPressed: () => reasonDialog(
                        title: 'Turn on every service for ${d.name}?',
                        message: 'All services become available again.',
                        confirm: 'Turn all on',
                        onConfirm: () => controller.setAllFeatures(true),
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Enable all'),
                    ),
                    TextButton.icon(
                      onPressed: () => reasonDialog(
                        title: 'Turn off every service for ${d.name}?',
                        message: 'Residents and admins lose access to all optional services. Data is kept.',
                        confirm: 'Turn all off',
                        danger: true,
                        onConfirm: () => controller.setAllFeatures(false),
                      ),
                      icon: const Icon(Icons.block_rounded, size: 18, color: AppColors.error),
                      label: const Text('Disable all', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ]),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(minHeight: 7, value: ratio, backgroundColor: AppColors.dividerLight, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final f in d.features) serviceRow(d, f),
        ],
      );
    }

    // ── Admins ──────────────────────────────────────────────────────────────
    adminsTab(SocietyDetail d) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(spacing: 12, children: [
            const IconTile(Icons.admin_panel_settings_outlined, AppColors.primary, size: 38),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Society admins', style: context.appText.sectionHeader),
                Text('${d.admins.length} ${d.admins.length == 1 ? 'person manages' : 'people manage'} this society', style: context.appText.timestamp),
              ]),
            ),
            if (canEdit) FilledButton.icon(onPressed: addAdminDialog, icon: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: const Text('Add admin')),
          ]),
          const SizedBox(height: 14),
          for (final a in d.admins)
            SoftCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  spacing: 14,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryLighter, AppColors.primary.withAlpha(70)]),
                      ),
                      child: Text(a.fullName.isEmpty ? '?' : a.fullName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 17)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(a.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          Wrap(spacing: 14, runSpacing: 4, children: [
                            MetaItem(Icons.mail_outline_rounded, a.email ?? 'no email'),
                            MetaItem(Icons.phone_outlined, a.phone),
                            MetaItem(Icons.login_rounded, a.lastLoginAt == null ? 'Never signed in' : 'Signed in ${timeAgo(a.lastLoginAt)}'),
                          ]),
                        ],
                      ),
                    ),
                    if (a.mustChangePassword) const PillTag('Temporary password', AppColors.orange),
                    if (canEdit)
                      OutlinedButton.icon(
                        onPressed: () => confirmDialog(
                          title: 'Reset password for ${a.fullName}?',
                          message: 'A new temporary password is generated, their current sessions end, and they must set a new password at next sign-in.',
                          confirm: 'Reset password',
                          onConfirm: () async {
                            final c = await controller.resetPassword(a);
                            if (c == null) return false;
                            Get.back();
                            credentialsDialog(c, title: 'New temporary password');
                            return false; // dialog already closed above
                          },
                        ),
                        icon: const Icon(Icons.lock_reset_rounded, size: 17),
                        label: const Text('Reset password'),
                      ),
                  ],
                ),
              ),
            ),
          if (d.admins.isEmpty)
            stateMessage(context, icon: Icons.person_off_outlined, title: 'No admins yet', subtitle: 'Add an admin so this society can sign in.', actionLabel: canEdit ? 'Add admin' : null, onAction: addAdminDialog),
        ],
      );
    }

    // ── Usage (M10) ─────────────────────────────────────────────────────────
    assignDialog() {
      controller.openAssign();
      Get.dialog(
        dialogShell(
          context,
          title: 'Change plan',
          subtitle: 'Price and services follow the plan',
          icon: Icons.workspace_premium_rounded,
          color: AppColors.orange,
          maxWidth: 480,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('The plan\'s price is copied into this society\'s subscription and its services are switched on or off to match. Limits start applying straight away; nothing is deleted if the society is already over one.', style: context.appText.timestamp),
              Obx(
                () => AppDropdown<String>(
                  initialValue: controller.pickedPlan.value.isEmpty ? null : controller.pickedPlan.value,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Plan', isDense: true),
                  items: [
                    for (final p in controller.plans)
                      DropdownMenuItem(value: p.id, child: Text('${p.name} · ${rupees(p.ratePerUnitPaise)}/flat${p.flatFeePaise > 0 ? ' + ${rupees(p.flatFeePaise)}' : ''}')),
                  ],
                  onChanged: (v) => controller.pickedPlan.value = v ?? '',
                ),
              ),
              Obx(
                () => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: controller.keepPrice.value,
                  onChanged: (v) => controller.keepPrice.value = v ?? false,
                  title: const Text('Keep this society\'s current price', style: TextStyle(fontSize: 13)),
                ),
              ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.dialogBusy.value
                    ? null
                    : () async {
                        final r = await controller.assignPlan();
                        if (r == null) return;
                        Get.back();
                        if (r.exceeded.isNotEmpty) {
                          Get.dialog(
                            dialogShell(
                              Get.context!,
                              title: 'Already over some limits',
                              maxWidth: 440,
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nothing was removed, but the society cannot add more of these until it is under the limit:', style: TextStyle(fontSize: 13)),
                                  const SizedBox(height: 8),
                                  for (final u in r.exceeded) Text('• ${u.name}: ${u.used} of ${u.max}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              actions: [FilledButton(onPressed: Get.back, child: const Text('OK'))],
                            ),
                          );
                        }
                      },
                child: const Text('Change plan'),
              ),
            ),
          ],
        ),
      );
    }

    usageTab(SocietyDetail d) {
      const labels = {
        'active_users': 'Active user-days',
        'logins': 'Sign-ins',
        'visitors': 'Visitors',
        'deliveries': 'Deliveries',
        'complaints_new': 'New complaints',
        'notices': 'Notices',
        'polls': 'Polls',
        'sos': 'SOS alerts',
        'bookings': 'Bookings',
        'invoices_issued': 'Invoices issued',
        'attendance_events': 'Attendance check-ins',
        'notifications': 'Notifications',
        'push': 'Push messages',
        'sms': 'SMS',
      };
      return Obx(() {
        if (controller.usageLoading.value) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
        final u = controller.usage.value;
        if (u == null) {
          return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load usage', subtitle: controller.usageError.value, actionLabel: 'Retry', onAction: controller.loadUsage);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cardBox(
              child: Row(
                children: [
                  const IconTile(Icons.workspace_premium_rounded, AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.planName, style: context.appText.sectionHeader),
                        if (u.differsFromPlan.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: pill('Services differ from the plan: ${u.differsFromPlan.join(', ')}', AppColors.warning, AppColors.warningLight),
                          ),
                      ],
                    ),
                  ),
                  if (canEdit) FilledButton.tonalIcon(onPressed: assignDialog, icon: const Icon(Icons.swap_horiz_rounded, size: 18), label: const Text('Change plan')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            cardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(Icons.speed_rounded, AppColors.primary, 'Limits'),
                  for (final r in u.usage) limitBar(r),
                ],
              ),
            ),
            const SizedBox(height: 14),
            cardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(Icons.insights_rounded, AppColors.teal, 'This month so far'),
                  Wrap(
                    spacing: 22,
                    runSpacing: 12,
                    children: [
                      for (final e in labels.entries)
                        SizedBox(
                          width: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(compact(u.monthTotals[e.key] ?? 0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                              Text(e.value, style: context.appText.timestamp),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 2 : 1;
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              Widget chart(String key, Color color) => SizedBox(
                width: w,
                child: cardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${labels[key] ?? key} · 30 days', style: context.appText.sectionHeader.copyWith(fontSize: 14)),
                      const SizedBox(height: 8),
                      trendChart(u.series[key] ?? const [], color: color, height: 140),
                    ],
                  ),
                ),
              );
              return Wrap(spacing: 14, runSpacing: 14, children: [
                chart('active_users', AppColors.primary),
                chart('visitors', AppColors.success),
                chart('complaints_new', AppColors.warning),
                chart('notifications', AppColors.primary),
              ]);
            }),
          ],
        );
      });
    }

    // ── Activity ────────────────────────────────────────────────────────────
    activityTab() {
      return Obx(() {
        if (controller.activityLoading.value) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
        if (controller.activity.isEmpty) {
          return stateMessage(context, icon: Icons.history_rounded, title: 'No activity recorded yet', subtitle: 'Changes made to this society show up here.');
        }
        return Column(children: [
          for (final r in controller.activity)
            SoftCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 14,
                  children: [
                    const IconTile(Icons.history_rounded, AppColors.primary, size: 36),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          Text(r.summary, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          MetaItem(Icons.person_outline_rounded, r.actorName ?? r.actorType),
                        ],
                      ),
                    ),
                    Text(formatDateTime(r.createdAt), style: context.appText.timestamp),
                  ],
                ),
              ),
            ),
        ]);
      });
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
          final d = controller.detail.value;
          if (controller.error.value.isNotEmpty && d == null) {
            return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load this society', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
          }
          if (d == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              headerView(d),
              if (d.isSuspended)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error.withAlpha(80))),
                  child: Row(spacing: 10, children: [
                    const Icon(Icons.block_rounded, color: AppColors.error),
                    Expanded(
                      child: Text('Suspended ${formatDate(d.suspendedAt)}: ${d.suspendedReason ?? ''}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              if (controller.notice.value.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.success.withAlpha(80))),
                  child: Row(spacing: 10, children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success),
                    Expanded(child: Text(controller.notice.value, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))),
                  ]),
                ),
              const SizedBox(height: 16),
              tabBar(),
              const SizedBox(height: 16),
              switch (controller.tab.value) {
                0 => overviewTab(d),
                1 => servicesTab(d),
                2 => adminsTab(d),
                3 => activityTab(),
                _ => usageTab(d),
              },
            ],
          );
        }),
      ),
    );
  }
}
