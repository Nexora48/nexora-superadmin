import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── KPI card ────────────────────────────────────────────────────────────
    kpi(String label, int value, IconData icon, Color color) {
      return cardBox(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                  Text(label, style: context.appText.timestamp),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Activity row ────────────────────────────────────────────────────────
    activityRow(row) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.circle, size: 8, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.summary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    [if (row.actorName != null) row.actorName, if (row.societyName != null) row.societyName, timeAgo(row.createdAt)].join(' · '),
                    style: context.appText.timestamp,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.error.value.isNotEmpty) {
        return stateMessage(context,
            icon: Icons.cloud_off_rounded, title: 'Could not load the dashboard', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
      }
      final s = controller.stats.value!;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Platform overview', style: context.appText.sectionHeader.copyWith(fontSize: 20)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
              final cards = [
                kpi('Societies', s.societies, Icons.apartment_rounded, AppColors.primary),
                kpi('Active', s.active, Icons.check_circle_outline_rounded, AppColors.success),
                kpi('On trial', s.trial, Icons.hourglass_empty_rounded, AppColors.warning),
                kpi('Suspended', s.suspended, Icons.pause_circle_outline_rounded, AppColors.error),
                kpi('Flats', s.flats, Icons.home_work_outlined, AppColors.primary),
                kpi('Residents', s.residents, Icons.people_outline_rounded, AppColors.primary),
                kpi('Society admins', s.admins, Icons.admin_panel_settings_outlined, AppColors.primary),
              ];
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [for (final c in cards) SizedBox(width: w, child: c)]);
            }),
            const SizedBox(height: 22),
            Text('Recent activity', style: context.appText.sectionHeader),
            const SizedBox(height: 8),
            cardBox(
              child: controller.recent.isEmpty
                  ? Text('Nothing yet.', style: context.appText.timestamp)
                  : Column(children: [for (final r in controller.recent) activityRow(r)]),
            ),
          ],
        ),
      );
    });
  }
}
