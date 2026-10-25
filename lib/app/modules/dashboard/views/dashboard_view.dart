import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/m10_models.dart';
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
      final o = controller.overview.value;

      // ── Usage KPI ─────────────────────────────────────────────────────────
      usageKpi(String label, String value, IconData icon) => cardBox(
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                  Text(label, style: context.appText.timestamp),
                ],
              ),
            ),
          ],
        ),
      );

      chartCard(String title, List<Point> pts, Color color) => cardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.appText.sectionHeader.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            trendChart(pts, color: color, height: 150),
          ],
        ),
      );

      alertsCard() => cardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Needs attention', style: context.appText.sectionHeader),
            const SizedBox(height: 8),
            if (o!.alerts.isEmpty)
              Row(children: [const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18), const SizedBox(width: 8), Text('Nothing right now.', style: context.appText.timestamp)])
            else
              for (final a in o.alerts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(a.kind == 'limit' ? Icons.speed_rounded : (a.kind == 'invoice' ? Icons.receipt_long_outlined : Icons.mark_email_unread_outlined), size: 17, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a.message, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
          ],
        ),
      );

      topCard() => cardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Most active societies', style: context.appText.sectionHeader),
            const SizedBox(height: 8),
            if (o!.top.isEmpty) Text('No activity in this period.', style: context.appText.timestamp),
            for (final (i, r) in o.top.take(5).indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 22, child: Text('${i + 1}', style: context.appText.timestamp)),
                  Expanded(child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text('${r.value} active-user days', style: context.appText.timestamp),
                ]),
              ),
          ],
        ),
      );

      unusedCard() => cardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enabled but unused (30 days)', style: context.appText.sectionHeader),
            const SizedBox(height: 8),
            if (o!.unused.isEmpty) Text('Every enabled service is in use.', style: context.appText.timestamp),
            for (final a in o.unused.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  pill('${a.unused.length} of ${a.enabled} societies', AppColors.warning, AppColors.warningLight),
                ]),
              ),
          ],
        ),
      );

      usageSection() {
        if (o == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Usage', style: context.appText.sectionHeader)),
                Obx(() => Wrap(spacing: 8, children: [
                      for (final r in DashboardController.ranges)
                        ChoiceChip(label: Text('$r days'), selected: controller.range.value == r, onSelected: (_) => controller.range.value = r),
                    ])),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              final cards = [
                usageKpi('Active societies (${o.rangeDays} d)', '${o.activeSocieties} of ${o.societies}', Icons.apartment_rounded),
                usageKpi('Daily active users', compact(o.dau), Icons.today_outlined),
                usageKpi('Monthly active users', compact(o.mau), Icons.calendar_month_outlined),
                usageKpi('Monthly recurring revenue', rupees(o.mrrPaise), Icons.payments_outlined),
              ];
              return Wrap(spacing: 14, runSpacing: 14, children: [for (final k in cards) SizedBox(width: w, child: k)]);
            }),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 1000 ? 2 : 1;
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                SizedBox(width: w, child: chartCard('Active users per day', o.series['active_users'] ?? const [], AppColors.primary)),
                SizedBox(width: w, child: chartCard('Visitors per day', o.series['visitors'] ?? const [], AppColors.success)),
              ]);
            }),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                SizedBox(width: w, child: alertsCard()),
                SizedBox(width: w, child: topCard()),
                SizedBox(width: w, child: unusedCard()),
              ]);
            }),
            const SizedBox(height: 22),
          ],
        );
      }

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
            usageSection(),
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
