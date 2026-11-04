import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/m10_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/system_controller.dart';

class SystemView extends GetView<SystemController> {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    // colour, soft colour and icon for a health status
    (Color, IconData) tone(String s) => switch (s) {
          'ok' => (AppColors.success, Icons.check_circle_rounded),
          'warn' => (AppColors.orange, Icons.warning_amber_rounded),
          _ => (AppColors.error, Icons.error_rounded),
        };

    // a small facts chip on the hero banner
    heroChip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(70))),
          child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
            Icon(icon, size: 15, color: AppColors.white),
            Text(text, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        );

    // ── Health ──────────────────────────────────────────────────────────────
    checkCard(HealthCheck c) {
      final (color, icon) = tone(c.status);
      return SoftCard(
        accent: color,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              IconTile(icon, color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(c.detail, style: context.appText.timestamp.copyWith(height: 1.4)),
                  ],
                ),
              ),
              PillTag(c.status == 'ok' ? 'OK' : (c.status == 'warn' ? 'Warning' : 'Failing'), color),
            ],
          ),
        ),
      );
    }

    healthSection(HealthReport h) {
      final (color, icon) = tone(h.status);
      final title = h.status == 'ok' ? 'All systems operational' : (h.status == 'warn' ? 'Needs attention' : 'There is a problem');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          // ── Hero banner ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.3)!]),
              boxShadow: [BoxShadow(color: color.withAlpha(70), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Row(
              spacing: 18,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(70))),
                  child: Icon(icon, color: AppColors.white, size: 34),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        heroChip(Icons.dns_outlined, 'API ${h.version}${h.commit.isEmpty ? '' : ' · ${h.commit}'}'),
                        heroChip(Icons.timer_outlined, 'Up ${controller.uptime(h.uptimeSeconds)}'),
                        heroChip(Icons.storage_rounded, 'Migration ${h.migration}'),
                      ]),
                    ],
                  ),
                ),
                IconButton.filledTonal(tooltip: 'Refresh', onPressed: controller.load, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [for (final k in h.checks) SizedBox(width: w, child: checkCard(k))]);
            },
          ),
          if (h.sweepers.isNotEmpty)
            cardBox(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Row(spacing: 12, children: [
                    const IconTile(Icons.autorenew_rounded, AppColors.teal, size: 38),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Background jobs', style: context.appText.sectionHeader),
                        Text('When each clean-up task last ran', style: context.appText.timestamp),
                      ]),
                    ),
                  ]),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    for (final s in h.sweepers)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                          Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(timeAgo(s.at), style: context.appText.timestamp),
                        ]),
                      ),
                  ]),
                ],
              ),
            ),
        ],
      );
    }

    // ── App versions ────────────────────────────────────────────────────────
    versionDialog(AppVersion v) {
      controller.openVersion(v);
      Get.dialog(
        dialogShell(
          context,
          title: v.label,
          subtitle: 'Control which builds of this app may run',
          icon: Icons.system_update_alt_rounded,
          color: AppColors.teal,
          maxWidth: 520,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Text('Apps older than the minimum show a blocking "update required" screen. Apps older than the latest show a dismissible banner.', style: context.appText.timestamp.copyWith(height: 1.4)),
              Row(spacing: 12, children: [
                Expanded(
                  child: TextField(
                    controller: controller.minCtrl,
                    decoration: const InputDecoration(labelText: 'Minimum version', hintText: '1.2.0', prefixIcon: Icon(Icons.block_rounded, size: 19)),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller.latestCtrl,
                    decoration: const InputDecoration(labelText: 'Latest version', hintText: '1.4.0', prefixIcon: Icon(Icons.new_releases_outlined, size: 19)),
                  ),
                ),
              ]),
              TextField(
                controller: controller.messageCtrl,
                maxLength: 300,
                decoration: const InputDecoration(labelText: 'Message shown to users', counterText: '', prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 19)),
              ),
              TextField(
                controller: controller.storeCtrl,
                decoration: const InputDecoration(labelText: 'Store or download link (https://…)', prefixIcon: Icon(Icons.link_rounded, size: 19)),
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
                        if (await controller.saveVersion(v)) Get.back();
                      },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      );
    }

    IconData appIcon(String label) {
      final l = label.toLowerCase();
      if (l.contains('get') || l.contains('guard')) return Icons.local_police_outlined;
      if (l.contains('admin')) return Icons.admin_panel_settings_outlined;
      return Icons.phone_iphone_rounded;
    }

    versionRow(AppVersion v) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(16)),
          child: Row(
            spacing: 14,
            children: [
              IconTile(appIcon(v.label), AppColors.teal),
              Expanded(
                flex: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                  Text(v.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(v.message.isEmpty ? 'No message set' : v.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.appText.timestamp),
                ]),
              ),
              Wrap(spacing: 8, runSpacing: 6, children: [
                PillTag('Min ${v.minVersion}', v.minVersion == '0.0.0' ? AppColors.textSecondaryLight : AppColors.error),
                PillTag('Latest ${v.latestVersion}', AppColors.success),
              ]),
              if (canEdit) IconButton(tooltip: 'Edit', onPressed: () => versionDialog(v), icon: const Icon(Icons.edit_outlined, size: 19)),
            ],
          ),
        );

    versionsSection() => cardBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Row(spacing: 12, children: [
                const IconTile(Icons.system_update_alt_rounded, AppColors.teal, size: 38),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('App versions', style: context.appText.sectionHeader),
                    Text('Control which builds of the apps may run. Left at 0.0.0 nothing is blocked.', style: context.appText.timestamp),
                  ]),
                ),
              ]),
              Obx(() => Column(children: [for (final v in controller.versions) versionRow(v)])),
            ],
          ),
        );

    // ── Audit retention ─────────────────────────────────────────────────────
    retentionDialog() {
      controller.retentionCtrl.text = '${controller.retentionDays.value}';
      controller.dialogError.value = '';
      Get.dialog(
        dialogShell(
          context,
          title: 'Audit log retention',
          subtitle: 'How long history is kept',
          icon: Icons.history_toggle_off_rounded,
          color: AppColors.purple,
          maxWidth: 460,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Text('Entries older than this are removed once a day (staff entries are kept twice as long). One summary entry records each clean-up.', style: context.appText.timestamp.copyWith(height: 1.4)),
              TextField(
                controller: controller.retentionCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Days (30 to 3650)', suffixText: 'days', prefixIcon: Icon(Icons.event_repeat_rounded, size: 19)),
              ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () async {
                if (await controller.saveRetention()) Get.back();
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      );
    }

    retentionSection() => cardBox(
          padding: const EdgeInsets.all(20),
          child: Row(
            spacing: 16,
            children: [
              const IconTile(Icons.history_toggle_off_rounded, AppColors.purple, size: 44),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Audit log retention', style: context.appText.sectionHeader),
                  Text('History is cleaned up once a day', style: context.appText.timestamp),
                ]),
              ),
              Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${controller.retentionDays.value}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.purple, height: 1)),
                    Text('days kept', style: context.appText.timestamp),
                  ])),
              if (canEdit) FilledButton.tonalIcon(onPressed: retentionDialog, icon: const Icon(Icons.edit_outlined, size: 17), label: const Text('Change')),
            ],
          ),
        );

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty && controller.health.value == null) {
        return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load system status', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('System', style: context.appText.sectionHeader.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
            Text('Health of the platform, app versions and data retention', style: context.appText.timestamp),
            const SizedBox(height: 16),
            noticeBar(controller.notice),
            healthSection(controller.health.value!),
            const SizedBox(height: 18),
            versionsSection(),
            const SizedBox(height: 14),
            retentionSection(),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }
}
