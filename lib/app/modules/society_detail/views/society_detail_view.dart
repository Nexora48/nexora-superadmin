import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
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

    // ── One-time credentials dialog ─────────────────────────────────────────
    credentialsDialog(Credentials c, {String title = 'Admin credentials'}) {
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('Email', c.email),
                infoRow('Mobile', c.phone),
                if (c.temporaryPassword != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: AppRadius.mdAll),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(c.temporaryPassword!,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () => Clipboard.setData(ClipboardData(text: c.temporaryPassword!)),
                          icon: const Icon(Icons.copy_rounded, size: 18),
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
          ),
          actions: [FilledButton(onPressed: Get.back, child: const Text('Done'))],
        ),
        barrierDismissible: false,
      );
    }

    // ── Reason dialog (suspend / services) ──────────────────────────────────
    reasonDialog({required String title, required String message, required String confirm, required Future<bool> Function() onConfirm, bool danger = false}) {
      controller.resetDialog();
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.reasonCtrl,
                  autofocus: true,
                  maxLength: 300,
                  decoration: const InputDecoration(labelText: 'Reason (saved in the audit log)'),
                ),
                dialogErr(),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(() => FilledButton(
                  style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
                  onPressed: controller.dialogBusy.value
                      ? null
                      : () async {
                          if (await onConfirm()) Get.back();
                        },
                  child: Text(confirm),
                )),
          ],
        ),
      );
    }

    confirmDialog({required String title, required String message, required String confirm, required Future<bool> Function() onConfirm}) {
      controller.resetDialog();
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(message), dialogErr()]),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(() => FilledButton(
                  onPressed: controller.dialogBusy.value
                      ? null
                      : () async {
                          if (await onConfirm()) Get.back();
                        },
                  child: Text(confirm),
                )),
          ],
        ),
      );
    }

    // ── Edit profile dialog ─────────────────────────────────────────────────
    editDialog() {
      controller.openEdit();
      Get.dialog(
        AlertDialog(
          title: const Text('Edit society'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: controller.nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 10),
                  TextField(controller: controller.addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: controller.cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: controller.stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
                  ]),
                  const SizedBox(height: 10),
                  TextField(controller: controller.pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode')),
                  dialogErr(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(() => FilledButton(
                  onPressed: controller.dialogBusy.value
                      ? null
                      : () async {
                          if (await controller.saveEdit()) Get.back();
                        },
                  child: const Text('Save'),
                )),
          ],
        ),
      );
    }

    // ── Add admin dialog ────────────────────────────────────────────────────
    addAdminDialog() {
      controller.openAddAdmin();
      Get.dialog(
        AlertDialog(
          title: const Text('Add society admin'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller.adminNameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 10),
                TextField(controller: controller.adminEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (used to sign in)')),
                const SizedBox(height: 10),
                TextField(controller: controller.adminPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile number', counterText: '')),
                dialogErr(),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(() => FilledButton(
                  onPressed: controller.dialogBusy.value
                      ? null
                      : () async {
                          final c = await controller.addAdmin();
                          if (c != null) {
                            Get.back();
                            credentialsDialog(c, title: 'Admin added');
                          }
                        },
                  child: const Text('Add admin'),
                )),
          ],
        ),
      );
    }

    // ── Header ──────────────────────────────────────────────────────────────
    headerView(SocietyDetail d) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(onPressed: Get.back, icon: const Icon(Icons.arrow_back_rounded)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(d.name, style: context.appText.sectionHeader.copyWith(fontSize: 20)),
              Text('${d.slug}${d.city.isEmpty ? '' : ' · ${d.city}'}', style: context.appText.timestamp),
            ],
          ),
          statusChip(d.status),
          if (canEdit) ...[
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
          ],
        ],
      );
    }

    // ── Tabs ────────────────────────────────────────────────────────────────
    tabBar() {
      const labels = ['Overview', 'Services', 'Admins', 'Activity', 'Usage'];
      return Obx(() => Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(label: Text(labels[i]), selected: controller.tab.value == i, onSelected: (_) => controller.selectTab(i)),
            ],
          ));
    }

    // ── Overview ────────────────────────────────────────────────────────────
    overviewTab(SocietyDetail d) {
      kpi(String label, String value) => SizedBox(
            width: 170,
            child: cardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(label, style: context.appText.timestamp),
                ],
              ),
            ),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            kpi('Blocks', '${d.blocks}'),
            kpi('Flats', '${d.flats}'),
            kpi('Residents', '${d.residents}'),
            kpi('Services on', '${d.enabledServices}/${d.totalServices}'),
          ]),
          const SizedBox(height: 16),
          cardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('Address', d.address),
                infoRow('City / State', [d.city, d.state].where((e) => e.isNotEmpty).join(', ')),
                infoRow('Pincode', d.pincode),
                infoRow('Onboarded', formatDate(d.createdAt)),
                infoRow('Last sign-in', d.lastSignIn == null ? 'never' : '${timeAgo(d.lastSignIn)} (${formatDateTime(d.lastSignIn)})'),
              ],
            ),
          ),
        ],
      );
    }

    // ── Services ────────────────────────────────────────────────────────────
    serviceRow(SocietyDetail d, FeatureRow f) {
      final overridden = f.override != null && f.override != f.defaultEnabled;
      return cardBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.extension_outlined, color: f.enabled ? AppColors.primary : AppColors.textSecondaryLight),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(f.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                    if (overridden) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: AppRadius.pill),
                        child: const Text('Overridden', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                      ),
                    ],
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
      );
    }

    servicesTab(SocietyDetail d) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${d.enabledServices} of ${d.totalServices} services are on. Changes apply to the API immediately; apps refresh within 5 minutes.',
                  style: context.appText.timestamp),
            ),
            if (canEdit) ...[
              TextButton(
                onPressed: () => reasonDialog(
                  title: 'Turn on every service for ${d.name}?',
                  message: 'All services become available again.',
                  confirm: 'Turn all on',
                  onConfirm: () => controller.setAllFeatures(true),
                ),
                child: const Text('Enable all'),
              ),
              TextButton(
                onPressed: () => reasonDialog(
                  title: 'Turn off every service for ${d.name}?',
                  message: 'Residents and admins lose access to all optional services. Data is kept.',
                  confirm: 'Turn all off',
                  danger: true,
                  onConfirm: () => controller.setAllFeatures(false),
                ),
                child: const Text('Disable all', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          for (final f in d.features) ...[serviceRow(d, f), const SizedBox(height: 8)],
        ],
      );
    }

    // ── Admins ──────────────────────────────────────────────────────────────
    adminsTab(SocietyDetail d) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(onPressed: addAdminDialog, icon: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: const Text('Add admin')),
            ),
          const SizedBox(height: 10),
          for (final a in d.admins) ...[
            cardBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: AppColors.primaryLighter, child: const Icon(Icons.person_outline_rounded, color: AppColors.primary)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('${a.email ?? 'no email'} · ${a.phone}', style: context.appText.timestamp),
                        Text('Last sign-in: ${a.lastLoginAt == null ? 'never' : timeAgo(a.lastLoginAt)}', style: context.appText.timestamp),
                      ],
                    ),
                  ),
                  if (a.mustChangePassword)
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: AppRadius.pill),
                      child: const Text('Temporary password', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                    ),
                  if (canEdit)
                    OutlinedButton(
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
                      child: const Text('Reset password'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (d.admins.isEmpty) Text('No admins yet.', style: context.appText.timestamp),
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
          maxWidth: 480,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('The plan\'s price is copied into this society\'s subscription and its services are switched on or off to match. Limits start applying straight away; nothing is deleted if the society is already over one.', style: context.appText.timestamp),
              Obx(
                () => DropdownButtonFormField<String>(
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
                  const Icon(Icons.workspace_premium_outlined, color: AppColors.primary),
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
                  if (canEdit) OutlinedButton(onPressed: assignDialog, child: const Text('Change plan')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            cardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Limits', style: context.appText.sectionHeader),
                  const SizedBox(height: 6),
                  for (final r in u.usage) limitBar(r),
                ],
              ),
            ),
            const SizedBox(height: 14),
            cardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This month so far', style: context.appText.sectionHeader),
                  const SizedBox(height: 10),
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
        if (controller.activity.isEmpty) return Text('No activity recorded yet.', style: context.appText.timestamp);
        return Column(children: [
          for (final r in controller.activity) ...[
            cardBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.summary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(r.actorName ?? r.actorType, style: context.appText.timestamp),
                      ],
                    ),
                  ),
                  Text(formatDateTime(r.createdAt), style: context.appText.timestamp),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
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
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: AppRadius.mdAll),
                  child: Text('Suspended ${formatDate(d.suspendedAt)}: ${d.suspendedReason ?? ''}',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
              if (controller.notice.value.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: AppRadius.mdAll),
                  child: Text(controller.notice.value, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
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
