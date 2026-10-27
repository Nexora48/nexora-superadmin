import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/m10_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/system_controller.dart';

class SystemView extends GetView<SystemController> {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    (Color, Color, IconData) tone(String s) => switch (s) {
      'ok' => (
        AppColors.success,
        AppColors.successLight,
        Icons.check_circle_outline_rounded,
      ),
      'warn' => (
        AppColors.warning,
        AppColors.warningLight,
        Icons.warning_amber_rounded,
      ),
      _ => (AppColors.error, AppColors.errorLight, Icons.error_outline_rounded),
    };

    // ── Health ──────────────────────────────────────────────────────────────
    checkCard(HealthCheck c) {
      final (fg, bg, icon) = tone(c.status);
      return cardBox(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(c.detail, style: context.appText.timestamp),
                ],
              ),
            ),
          ],
        ),
      );
    }

    healthSection(HealthReport h) {
      final (fg, bg, _) = tone(h.status);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('System health', style: context.appText.sectionHeader),
              const SizedBox(width: 10),
              pill(
                h.status == 'ok'
                    ? 'All good'
                    : (h.status == 'warn' ? 'Needs attention' : 'Problem'),
                fg,
                bg,
              ),
              const Spacer(),
              Text(
                'API ${h.version}${h.commit.isEmpty ? '' : ' (${h.commit})'} · up ${controller.uptime(h.uptimeSeconds)} · migration ${h.migration}',
                style: context.appText.timestamp,
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final k in h.checks)
                    SizedBox(width: w, child: checkCard(k)),
                ],
              );
            },
          ),
          if (h.sweepers.isNotEmpty) ...[
            const SizedBox(height: 14),
            cardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background jobs',
                    style: context.appText.sectionHeader.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      for (final s in h.sweepers)
                        Text(
                          '${s.name}: ${timeAgo(s.at)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Apps older than the minimum show a blocking "update required" screen. Apps older than the latest show a dismissible banner.',
                style: context.appText.timestamp,
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.minCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Minimum version',
                        hintText: '1.2.0',
                        isDense: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.latestCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Latest version',
                        hintText: '1.4.0',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: controller.messageCtrl,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Message shown to users',
                  counterText: '',
                  isDense: true,
                ),
              ),
              TextField(
                controller: controller.storeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Store or download link (https://…)',
                  isDense: true,
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
                        if (await controller.saveVersion(v)) Get.back();
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      );
    }

    versionRow(AppVersion v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              v.label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              'min ${v.minVersion}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              'latest ${v.latestVersion}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              v.message.isEmpty ? '—' : v.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.appText.timestamp,
            ),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Edit',
              onPressed: () => versionDialog(v),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
        ],
      ),
    );

    versionsSection() => cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App versions', style: context.appText.sectionHeader),
          const SizedBox(height: 4),
          Text(
            'Control which builds of the apps may run. Left at 0.0.0 nothing is blocked.',
            style: context.appText.timestamp,
          ),
          const SizedBox(height: 8),
          Obx(
            () => Column(
              children: [
                for (final v in controller.versions) ...[
                  versionRow(v),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
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
          maxWidth: 440,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entries older than this are removed once a day (staff entries are kept twice as long). One summary entry records each clean-up.',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.retentionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days (30 to 3650)',
                  isDense: true,
                ),
              ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (await controller.saveRetention()) Get.back();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    retentionSection() => cardBox(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audit log retention',
                  style: context.appText.sectionHeader,
                ),
                Obx(
                  () => Text(
                    'Entries are kept for ${controller.retentionDays.value} days.',
                    style: context.appText.timestamp,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            OutlinedButton(
              onPressed: retentionDialog,
              child: const Text('Change'),
            ),
        ],
      ),
    );

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty &&
          controller.health.value == null) {
        return stateMessage(
          context,
          icon: Icons.cloud_off_rounded,
          title: 'Could not load system status',
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
            noticeBar(controller.notice),
            healthSection(controller.health.value!),
            const SizedBox(height: 22),
            versionsSection(),
            const SizedBox(height: 14),
            retentionSection(),
          ],
        ),
      );
    });
  }
}
