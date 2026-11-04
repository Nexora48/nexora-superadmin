import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/m10_models.dart';
import '../controllers/staff_controller.dart';

class StaffView extends GetView<StaffController> {
  const StaffView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Invitation token (shown once) ───────────────────────────────────────
    tokenDialog(InviteResult r) {
      final link = '${Uri.base.origin}/#/accept-invite?token=${r.token}';
      Get.dialog(
        dialogShell(
          context,
          title: 'Invitation for ${r.user.fullName}',
          subtitle: 'The link works once and expires in 72 hours',
          icon: Icons.mark_email_read_outlined,
          color: AppColors.teal,
          maxWidth: 560,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Text(
                r.emailed
                    ? 'An invitation e-mail was sent to ${r.user.email}. Keep this link in case the e-mail does not arrive. It is not shown again.'
                    : 'No e-mail was sent (the mail server is not configured). Send this link to the new staff member yourself. It is not shown again.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.dividerLight)),
                child: Row(spacing: 10, children: [
                  const Icon(Icons.link_rounded, color: AppColors.teal),
                  Expanded(child: SelectableText(link, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Close')),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                Get.back();
                controller.flash('Invitation link copied');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy link'),
            ),
          ],
        ),
      );
    }

    inviteDialog() {
      controller.openInvite();
      Get.dialog(
        dialogShell(
          context,
          title: 'Invite staff',
          subtitle: 'They get an e-mail with a one-time sign-up link',
          icon: Icons.person_add_alt_1_rounded,
          maxWidth: 480,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              TextField(
                controller: controller.nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
              ),
              TextField(
                controller: controller.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Work email', prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
              ),
              Obx(
                () => AppDropdown<String>(
                  initialValue: controller.inviteRole.value,
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20)),
                  items: const [
                    DropdownMenuItem(value: 'platform_support', child: Text('Support (read-only)')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super admin (can change everything)')),
                  ],
                  onChanged: (v) => controller.inviteRole.value = v ?? 'platform_support',
                ),
              ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        final r = await controller.invite();
                        if (r != null) {
                          Get.back();
                          tokenDialog(r);
                        }
                      },
                icon: const Icon(Icons.send_rounded, size: 17),
                label: const Text('Send invitation'),
              ),
            ),
          ],
        ),
      );
    }

    confirm(String title, String text, Future<String?> Function() action, {String label = 'Confirm', bool danger = false}) {
      final err = ''.obs;
      Get.dialog(
        dialogShell(
          context,
          title: title,
          icon: danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
          color: danger ? AppColors.error : AppColors.primary,
          maxWidth: 460,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(text, style: const TextStyle(fontSize: 14, height: 1.4)), dialogErrorText(err)],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            FilledButton(
              style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
              onPressed: () async {
                final e = await action();
                if (e == null) {
                  Get.back();
                } else {
                  err.value = e;
                }
              },
              child: Text(label),
            ),
          ],
        ),
      );
    }

    // ── Summary tiles ───────────────────────────────────────────────────────
    summaryTile(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(spacing: 12, children: [
            IconTile(icon, color),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.1)),
                Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
    }

    teamSummary() {
      final all = controller.staff.toList();
      final supers = all.where((m) => m.isSuper).length;
      final mfa = all.where((m) => m.mfaEnabled).length;
      final pending = all.where((m) => m.invitePending).length;
      final tiles = [
        summaryTile(Icons.groups_2_outlined, AppColors.primary, '${all.length}', 'Team members'),
        summaryTile(Icons.verified_user_outlined, AppColors.purple, '$supers', 'Super admins'),
        summaryTile(Icons.lock_outline_rounded, AppColors.success, '$mfa', 'With 2-step on'),
        summaryTile(Icons.hourglass_top_rounded, AppColors.orange, '$pending', 'Invites pending'),
      ];
      return LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(spacing: 10, children: [Row(spacing: 10, children: [tiles[0], tiles[1]]), Row(spacing: 10, children: [tiles[2], tiles[3]])]);
        }
        return Row(spacing: 12, children: tiles);
      });
    }

    // ── Team ────────────────────────────────────────────────────────────────
    memberRow(StaffMember m) {
      final me = m.id == controller.myId;
      final statusColor = m.invitePending ? AppColors.orange : (m.disabled ? AppColors.error : AppColors.success);
      final statusText = m.invitePending ? 'Invited' : (m.disabled ? 'Disabled' : 'Active');
      final roleColor = m.isSuper ? AppColors.purple : AppColors.teal;
      return SoftCard(
        accent: statusColor,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 14,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [roleColor.withAlpha(60), roleColor.withAlpha(140)]),
                ),
                child: Text(m.fullName.isEmpty ? '?' : m.fullName[0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (me) const PillTag('You', AppColors.primary),
                    ]),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      MetaItem(Icons.mail_outline_rounded, m.email),
                      MetaItem(Icons.login_rounded, m.lastLoginAt == null ? 'Never signed in' : 'Signed in ${timeAgo(m.lastLoginAt)}'),
                    ]),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  PillTag(m.roleLabel, roleColor),
                  PillTag(m.mfaEnabled ? '2-step on' : '2-step off', m.mfaEnabled ? AppColors.success : AppColors.orange),
                  PillTag(statusText, statusColor),
                ],
              ),
              SizedBox(
                width: 40,
                child: me
                    ? const SizedBox.shrink()
                    : PopupMenuButton<String>(
                        tooltip: 'Actions',
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (v) async {
                          switch (v) {
                            case 'reinvite':
                              final r = await controller.reinvite(m);
                              if (r != null) tokenDialog(r);
                            case 'role':
                              confirm(
                                m.isSuper ? 'Make ${m.fullName} support-only?' : 'Make ${m.fullName} a super admin?',
                                m.isSuper ? 'They will be able to read everything but change nothing.' : 'They will be able to change plans, services, staff and billing.',
                                () => controller.change(m, role: m.isSuper ? 'platform_support' : 'super_admin'),
                              );
                            case 'status':
                              confirm(
                                m.disabled ? 'Enable ${m.fullName}?' : 'Disable ${m.fullName}?',
                                m.disabled ? 'They can sign in again.' : 'They are signed out everywhere and cannot sign in until enabled.',
                                () => controller.change(m, status: m.disabled ? 'active' : 'disabled'),
                                danger: !m.disabled,
                              );
                            case 'mfa':
                              confirm(
                                'Reset ${m.fullName}\'s authenticator?',
                                'Their current code and recovery codes stop working. They set up a new authenticator at the next sign-in.',
                                () => controller.resetMfa(m),
                                danger: true,
                              );
                          }
                        },
                        itemBuilder: (_) => [
                          if (m.invitePending) const PopupMenuItem(value: 'reinvite', child: Row(spacing: 10, children: [Icon(Icons.link_rounded, size: 18), Text('New invitation link')])),
                          if (!m.invitePending)
                            PopupMenuItem(value: 'role', child: Row(spacing: 10, children: [const Icon(Icons.swap_horiz_rounded, size: 18), Text(m.isSuper ? 'Make support (read-only)' : 'Make super admin')])),
                          PopupMenuItem(value: 'status', child: Row(spacing: 10, children: [Icon(m.disabled ? Icons.check_circle_outline_rounded : Icons.block_rounded, size: 18), Text(m.disabled ? 'Enable' : 'Disable')])),
                          if (m.mfaEnabled) const PopupMenuItem(value: 'mfa', child: Row(spacing: 10, children: [Icon(Icons.phonelink_lock_rounded, size: 18, color: AppColors.error), Text('Reset authenticator', style: TextStyle(color: AppColors.error))])),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    }

    team() {
      return Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            teamSummary(),
            const SizedBox(height: 16),
            for (final m in controller.staff) memberRow(m),
          ]));
    }

    // ── Broadcast composer ──────────────────────────────────────────────────
    composeDialog() {
      controller.openCompose();
      Get.dialog(
        dialogShell(
          context,
          title: 'New broadcast',
          subtitle: 'A notice sent to society admins, optionally to residents too',
          icon: Icons.campaign_rounded,
          color: AppColors.orange,
          maxWidth: 680,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              TextField(
                controller: controller.titleCtrl,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Title', counterText: '', prefixIcon: Icon(Icons.title_rounded, size: 20)),
              ),
              TextField(
                controller: controller.bodyCtrl,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Message', counterText: '', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded, size: 20)),
              ),
              TextField(
                controller: controller.linkCtrl,
                decoration: const InputDecoration(labelText: 'Link (optional, https://…)', prefixIcon: Icon(Icons.link_rounded, size: 20)),
              ),
              Row(spacing: 8, children: [
                const Icon(Icons.groups_2_outlined, size: 18, color: AppColors.primary),
                Text('Who receives it', style: context.appText.sectionHeader.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              Obx(
                () => Segmented(
                  items: const ['All societies', 'By plan', 'Selected'],
                  selected: const ['all', 'plans', 'societies'].indexOf(controller.audienceMode.value),
                  onTap: (i) {
                    controller.audienceMode.value = const ['all', 'plans', 'societies'][i];
                    controller.previewCount.value = -1;
                  },
                ),
              ),
              Obx(() {
                if (controller.audienceMode.value == 'plans') {
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in controller.plans)
                      FilterChip(
                        label: Text(p.name),
                        selected: controller.pickedPlans.contains(p.id),
                        onSelected: (v) {
                          v ? controller.pickedPlans.add(p.id) : controller.pickedPlans.remove(p.id);
                          controller.previewCount.value = -1;
                        },
                      ),
                  ]);
                }
                if (controller.audienceMode.value == 'societies') {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final s in controller.societies)
                          FilterChip(
                            label: Text(s.name),
                            selected: controller.pickedSocieties.contains(s.id),
                            onSelected: (v) {
                              v ? controller.pickedSocieties.add(s.id) : controller.pickedSocieties.remove(s.id);
                              controller.previewCount.value = -1;
                            },
                          ),
                      ]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(
                () => Container(
                  decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14)),
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    value: controller.includeResidents.value,
                    onChanged: (v) {
                      controller.includeResidents.value = v ?? false;
                      controller.previewCount.value = -1;
                    },
                    title: const Text('Also send to committee members and residents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('By default only society admins receive it.', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              Row(spacing: 12, children: [
                FilledButton.tonalIcon(onPressed: controller.preview, icon: const Icon(Icons.calculate_outlined, size: 18), label: const Text('Count recipients')),
                Obx(() => controller.previewCount.value < 0
                    ? const SizedBox.shrink()
                    : PillTag(controller.previewCount.value == 1 ? '1 person' : '${controller.previewCount.value} people', AppColors.success)),
              ]),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.send()) Get.back();
                      },
                icon: const Icon(Icons.send_rounded, size: 17),
                label: const Text('Send'),
              ),
            ),
          ],
        ),
      );
    }

    broadcastRow(Broadcast b) {
      final color = switch (b.status) {
        'sent' => AppColors.success,
        'cancelled' => AppColors.textSecondaryLight,
        _ => AppColors.orange,
      };
      return SoftCard(
        accent: color,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              const IconTile(Icons.campaign_outlined, AppColors.orange),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(b.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.appText.timestamp.copyWith(height: 1.4)),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      MetaItem(Icons.groups_2_outlined, '${b.audienceLabel}${b.includeResidents ? ' + residents' : ''}'),
                      MetaItem(Icons.mark_email_read_outlined, '${b.sentCount}/${b.recipients} delivered'),
                      if ((b.senderName ?? '').isNotEmpty) MetaItem(Icons.person_outline_rounded, b.senderName!),
                      MetaItem(Icons.schedule_rounded, timeAgo(b.createdAt)),
                    ]),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, spacing: 6, children: [
                PillTag(b.status, color),
                if (b.cancellable) TextButton.icon(onPressed: () => controller.cancel(b), icon: const Icon(Icons.cancel_outlined, size: 16), label: const Text('Cancel')),
              ]),
            ],
          ),
        ),
      );
    }

    broadcastList() {
      return Obx(() {
        final list = controller.broadcasts.toList();
        if (list.isEmpty) {
          return stateMessage(context, icon: Icons.campaign_outlined, title: 'No broadcasts yet', subtitle: 'Send a notice to society admins, or to residents too.', actionLabel: 'New broadcast', onAction: composeDialog);
        }
        return Column(children: [for (final b in list) broadcastRow(b)]);
      });
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load staff', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Staff & broadcast', style: context.appText.sectionHeader.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
                    Text('The Nexora team and the notices sent to societies', style: context.appText.timestamp),
                  ]),
                ),
                if (controller.tab.value == 0)
                  FilledButton.icon(onPressed: inviteDialog, icon: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: const Text('Invite staff'))
                else
                  FilledButton.icon(onPressed: composeDialog, icon: const Icon(Icons.campaign_outlined, size: 18), label: const Text('New broadcast')),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Segmented(items: const ['Team', 'Broadcast'], selected: controller.tab.value, onTap: (i) => controller.tab.value = i),
            ),
            const SizedBox(height: 14),
            noticeBar(controller.notice),
            if (controller.tab.value == 0) team() else broadcastList(),
          ],
        ),
      );
    });
  }
}
