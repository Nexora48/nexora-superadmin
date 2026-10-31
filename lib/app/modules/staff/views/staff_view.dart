import 'package:nexora_superadmin/app/core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.emailed
                    ? 'An invitation e-mail was sent to ${r.user.email}. The link below works once and expires in 72 hours; keep it in case the e-mail does not arrive. It is not shown again.'
                    : 'No e-mail was sent (the mail server is not configured). Send this link to the new staff member yourself. It works once and expires in 72 hours, and it is not shown again.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SelectableText(
                link,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              TextField(
                controller: controller.nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  isDense: true,
                ),
              ),
              TextField(
                controller: controller.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Work email',
                  isDense: true,
                ),
              ),
              Obx(
                () => AppDropdown<String>(
                  initialValue: controller.inviteRole.value,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'platform_support',
                      child: Text('Support (read-only)'),
                    ),
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('Super admin (can change everything)'),
                    ),
                  ],
                  onChanged: (v) =>
                      controller.inviteRole.value = v ?? 'platform_support',
                ),
              ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        final r = await controller.invite();
                        if (r != null) {
                          Get.back();
                          tokenDialog(r);
                        }
                      },
                child: const Text('Send invitation'),
              ),
            ),
          ],
        ),
      );
    }

    confirm(
      String title,
      String text,
      Future<String?> Function() action, {
      String label = 'Confirm',
    }) {
      final err = ''.obs;
      Get.dialog(
        dialogShell(
          context,
          title: title,
          maxWidth: 440,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 13)),
              dialogErrorText(err),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            FilledButton(
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

    // ── Team table ──────────────────────────────────────────────────────────
    memberRow(StaffMember m) {
      final me = m.id == controller.myId;
      final status = m.invitePending
          ? pill('Invited', AppColors.warning, AppColors.warningLight)
          : m.disabled
          ? pill('Disabled', AppColors.error, AppColors.errorLight)
          : pill('Active', AppColors.success, AppColors.successLight);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.fullName}${me ? '  (you)' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(m.email, style: context.appText.timestamp),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(m.roleLabel, style: const TextStyle(fontSize: 13)),
            ),
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: status),
            ),
            Expanded(
              child: Text(
                m.mfaEnabled ? 'On' : 'Not set up',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                m.lastLoginAt == null ? 'never' : timeAgo(m.lastLoginAt),
                style: context.appText.timestamp,
              ),
            ),
            SizedBox(
              width: 52,
              child: me
                  ? const SizedBox.shrink()
                  : PopupMenuButton<String>(
                      tooltip: 'Actions',
                      onSelected: (v) async {
                        switch (v) {
                          case 'reinvite':
                            final r = await controller.reinvite(m);
                            if (r != null) tokenDialog(r);
                          case 'role':
                            confirm(
                              m.isSuper
                                  ? 'Make ${m.fullName} support-only?'
                                  : 'Make ${m.fullName} a super admin?',
                              m.isSuper
                                  ? 'They will be able to read everything but change nothing.'
                                  : 'They will be able to change plans, services, staff and billing.',
                              () => controller.change(
                                m,
                                role: m.isSuper
                                    ? 'platform_support'
                                    : 'super_admin',
                              ),
                            );
                          case 'status':
                            confirm(
                              m.disabled
                                  ? 'Enable ${m.fullName}?'
                                  : 'Disable ${m.fullName}?',
                              m.disabled
                                  ? 'They can sign in again.'
                                  : 'They are signed out everywhere and cannot sign in until enabled.',
                              () => controller.change(
                                m,
                                status: m.disabled ? 'active' : 'disabled',
                              ),
                            );
                          case 'mfa':
                            confirm(
                              'Reset ${m.fullName}\'s authenticator?',
                              'Their current code and recovery codes stop working. They set up a new authenticator at the next sign-in.',
                              () => controller.resetMfa(m),
                            );
                        }
                      },
                      itemBuilder: (_) => [
                        if (m.invitePending)
                          const PopupMenuItem(
                            value: 'reinvite',
                            child: Text('New invitation link'),
                          ),
                        if (!m.invitePending)
                          PopupMenuItem(
                            value: 'role',
                            child: Text(
                              m.isSuper
                                  ? 'Make support (read-only)'
                                  : 'Make super admin',
                            ),
                          ),
                        PopupMenuItem(
                          value: 'status',
                          child: Text(m.disabled ? 'Enable' : 'Disable'),
                        ),
                        if (m.mfaEnabled)
                          const PopupMenuItem(
                            value: 'mfa',
                            child: Text('Reset authenticator'),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    team() {
      return Obx(
        () => cardBox(
          child: Column(
            children: [
              Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Role',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '2-step',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Last sign-in',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 52),
                ],
              ),
              const Divider(),
              for (final m in controller.staff) ...[
                memberRow(m),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
      );
    }

    // ── Broadcast composer ──────────────────────────────────────────────────
    composeDialog() {
      controller.openCompose();
      Get.dialog(
        dialogShell(
          context,
          title: 'New broadcast',
          maxWidth: 640,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              TextField(
                controller: controller.titleCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  counterText: '',
                  isDense: true,
                ),
              ),
              TextField(
                controller: controller.bodyCtrl,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  counterText: '',
                  isDense: true,
                ),
              ),
              TextField(
                controller: controller.linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link (optional, https://…)',
                  isDense: true,
                ),
              ),
              Text(
                'Who receives it',
                style: context.appText.sectionHeader.copyWith(fontSize: 14),
              ),
              Obx(
                () => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All societies')),
                    ButtonSegment(value: 'plans', label: Text('By plan')),
                    ButtonSegment(value: 'societies', label: Text('Selected')),
                  ],
                  selected: {controller.audienceMode.value},
                  onSelectionChanged: (s) {
                    controller.audienceMode.value = s.first;
                    controller.previewCount.value = -1;
                  },
                ),
              ),
              Obx(() {
                if (controller.audienceMode.value == 'plans') {
                  return Wrap(
                    spacing: 8,
                    children: [
                      for (final p in controller.plans)
                        FilterChip(
                          label: Text(p.name),
                          selected: controller.pickedPlans.contains(p.id),
                          onSelected: (v) {
                            v
                                ? controller.pickedPlans.add(p.id)
                                : controller.pickedPlans.remove(p.id);
                            controller.previewCount.value = -1;
                          },
                        ),
                    ],
                  );
                }
                if (controller.audienceMode.value == 'societies') {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final s in controller.societies)
                            FilterChip(
                              label: Text(s.name),
                              selected: controller.pickedSocieties.contains(
                                s.id,
                              ),
                              onSelected: (v) {
                                v
                                    ? controller.pickedSocieties.add(s.id)
                                    : controller.pickedSocieties.remove(s.id);
                                controller.previewCount.value = -1;
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(
                () => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: controller.includeResidents.value,
                  onChanged: (v) {
                    controller.includeResidents.value = v ?? false;
                    controller.previewCount.value = -1;
                  },
                  title: const Text(
                    'Also send to committee members and residents',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'By default only society admins receive it.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.preview,
                    child: const Text('Count recipients'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => Text(
                      controller.previewCount.value < 0
                          ? ''
                          : (controller.previewCount.value == 1
                                ? '1 person'
                                : '${controller.previewCount.value} people'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.send()) Get.back();
                      },
                child: const Text('Send'),
              ),
            ),
          ],
        ),
      );
    }

    broadcastRow(Broadcast b) {
      final (fg, bg) = switch (b.status) {
        'sent' => (AppColors.success, AppColors.successLight),
        'cancelled' => (
          AppColors.textSecondaryLight,
          AppColors.backgroundLight,
        ),
        _ => (AppColors.warning, AppColors.warningLight),
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    b.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.appText.timestamp,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.audienceLabel}${b.includeResidents ? ' + residents' : ''} · ${b.sentCount}/${b.recipients} delivered · ${b.senderName ?? ''} · ${timeAgo(b.createdAt)}',
                    style: context.appText.timestamp,
                  ),
                ],
              ),
            ),
            pill(b.status, fg, bg),
            if (b.cancellable)
              TextButton(
                onPressed: () => controller.cancel(b),
                child: const Text('Cancel'),
              ),
          ],
        ),
      );
    }

    broadcastList() {
      return Obx(
        () => cardBox(
          child: controller.broadcasts.isEmpty
              ? Text('No broadcasts yet.', style: context.appText.timestamp)
              : Column(
                  children: [
                    for (final b in controller.broadcasts) ...[
                      broadcastRow(b),
                      const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      );
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return stateMessage(
          context,
          icon: Icons.cloud_off_rounded,
          title: 'Could not load staff',
          subtitle: controller.error.value,
          actionLabel: 'Retry',
          onAction: controller.load,
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Staff & broadcast',
                    style: context.appText.sectionHeader.copyWith(fontSize: 20),
                  ),
                ),
                if (controller.tab.value == 0)
                  FilledButton.icon(
                    onPressed: inviteDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Invite staff'),
                  )
                else
                  FilledButton.icon(
                    onPressed: composeDialog,
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('New broadcast'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Team')),
                ButtonSegment(value: 1, label: Text('Broadcast')),
              ],
              selected: {controller.tab.value},
              onSelectionChanged: (s) => controller.tab.value = s.first,
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
