import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/m10_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../routes/app_pages.dart';
import '../../../services/platform_auth_service.dart';
import '../../main_layout/controllers/main_layout_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── A white card with an icon title ─────────────────────────────────────
    panel({required IconData icon, required Color color, required String title, String? subtitle, Widget? trailing, required Widget child}) {
      return cardBox(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(spacing: 12, children: [
              IconTile(icon, color, size: 38),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: context.appText.sectionHeader),
                  if (subtitle != null) Text(subtitle, style: context.appText.timestamp),
                ]),
              ),
              if (trailing != null) trailing,
            ]),
            child,
          ],
        ),
      );
    }

    // ── KPI tile ────────────────────────────────────────────────────────────
    kpi(String label, String value, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(spacing: 14, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.22)!]),
              boxShadow: [BoxShadow(color: color.withAlpha(70), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: AppColors.white, size: 23),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.25), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );
    }

    // ── Hero banner ─────────────────────────────────────────────────────────
    String greeting() {
      final h = DateTime.now().hour;
      return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
    }

    heroChip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withAlpha(36), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(64))),
          child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
            Icon(icon, size: 15, color: AppColors.white),
            Text(text, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        );

    hero(PlatformStats s, Overview? o) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final now = DateTime.now();
      final first = (PlatformAuthService.to.user.value?.fullName ?? '').split(' ').first;
      final canEdit = PlatformAuthService.to.canEdit;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1877F2), Color(0xFF0F2A5C)]),
          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(70), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(right: -50, top: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(16)))),
            Positioned(right: 90, bottom: -80, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(12)))),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 18,
              spacing: 20,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text('${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${greeting()}${first.isEmpty ? '' : ', $first'}', style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w600)),
                    Text('Here is how Nexora is doing across every society.', style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 14)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      heroChip(Icons.apartment_rounded, '${s.societies} societies'),
                      heroChip(Icons.people_outline_rounded, '${s.residents} residents'),
                      if (o != null) heroChip(Icons.currency_rupee_rounded, '${rupees(o.mrrPaise)} a month'),
                    ]),
                  ],
                ),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  if (canEdit)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.primaryDarker, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                      onPressed: () => Get.toNamed(Routes.societyCreate),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text('Onboard society'),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.white, side: BorderSide(color: Colors.white.withAlpha(120)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                    onPressed: () => Get.find<MainLayoutController>().select(6),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Audit log'),
                  ),
                ]),
              ],
            ),
          ],
        ),
      );
    }

    // ── Society status breakdown ────────────────────────────────────────────
    statusBreakdown(PlatformStats s) {
      final total = s.societies == 0 ? 1 : s.societies;
      seg(int n, Color c) => n == 0 ? const SizedBox.shrink() : Expanded(flex: n, child: Container(height: 12, color: c));
      legend(Color c, String label, int n) => Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            Text(label, style: context.appText.timestamp),
            Text('$n · ${(n * 100 / total).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]);
      return panel(
        icon: Icons.donut_large_rounded,
        color: AppColors.primary,
        title: 'Society status',
        subtitle: '${s.societies} societies on the platform',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: s.societies == 0
                ? Container(height: 12, color: AppColors.dividerLight)
                : Row(children: [seg(s.active, AppColors.success), seg(s.trial, AppColors.orange), seg(s.suspended, AppColors.error)]),
          ),
          Wrap(spacing: 22, runSpacing: 8, children: [
            legend(AppColors.success, 'Active', s.active),
            legend(AppColors.orange, 'On trial', s.trial),
            legend(AppColors.error, 'Suspended', s.suspended),
          ]),
        ]),
      );
    }

    // ── Chart panel ─────────────────────────────────────────────────────────
    chartCard(String title, IconData icon, List<Point> pts, Color color) {
      final total = pts.fold<int>(0, (a, p) => a + p.value);
      return panel(
        icon: icon,
        color: color,
        title: title,
        subtitle: 'Total ${compact(total)} in this range',
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 12, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withAlpha(16), color.withAlpha(3)]),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: trendChart(pts, color: color, height: 170),
        ),
      );
    }

    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.error.value.isNotEmpty) {
        return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load the dashboard', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
      }
      final s = controller.stats.value!;
      final o = controller.overview.value;

      // ── Usage tile ────────────────────────────────────────────────────────
      usageKpi(String label, String value, IconData icon, Color color) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.dividerLight),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(spacing: 12, children: [
              IconTile(icon, color),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          );

      alertsCard() => panel(
            icon: Icons.notifications_active_outlined,
            color: AppColors.orange,
            title: 'Needs attention',
            subtitle: o!.alerts.isEmpty ? 'All clear' : '${o.alerts.length} item${o.alerts.length == 1 ? '' : 's'}',
            child: o.alerts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(14)),
                    child: Row(spacing: 10, children: [
                      const Icon(Icons.verified_rounded, color: AppColors.success),
                      Expanded(child: Text('Nothing needs your attention right now.', style: context.appText.timestamp)),
                    ]),
                  )
                : Column(spacing: 8, children: [
                    for (final a in o.alerts)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                          Icon(a.kind == 'limit' ? Icons.speed_rounded : (a.kind == 'invoice' ? Icons.receipt_long_outlined : Icons.mark_email_unread_outlined), size: 18, color: AppColors.orange),
                          Expanded(child: Text(a.message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        ]),
                      ),
                  ]),
          );

      topCard() {
        const medal = [Color(0xFFF5B301), Color(0xFF9AA5B1), Color(0xFFCD7F32)];
        final top = o!.top.take(5).toList();
        final maxV = top.isEmpty ? 1 : top.map((r) => r.value).reduce((a, b) => a > b ? a : b);
        return panel(
          icon: Icons.emoji_events_rounded,
          color: AppColors.orange,
          title: 'Most active societies',
          subtitle: 'By active-user days',
          child: top.isEmpty
              ? Text('No activity in this period.', style: context.appText.timestamp)
              : Column(spacing: 12, children: [
                  for (final (i, r) in top.indexed)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
                      Row(spacing: 10, children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: i < 3 ? medal[i] : AppColors.backgroundLight),
                          child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: i < 3 ? AppColors.white : AppColors.textSecondaryLight)),
                        ),
                        Expanded(child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        Text('${r.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(minHeight: 6, value: r.value / maxV, backgroundColor: AppColors.dividerLight, valueColor: AlwaysStoppedAnimation(i < 3 ? medal[i] : AppColors.primary)),
                      ),
                    ]),
                ]),
        );
      }

      unusedCard() => panel(
            icon: Icons.visibility_off_outlined,
            color: AppColors.purple,
            title: 'Enabled but unused',
            subtitle: 'Last 30 days',
            child: o!.unused.isEmpty
                ? Text('Every enabled service is in use.', style: context.appText.timestamp)
                : Column(spacing: 10, children: [
                    for (final a in o.unused.take(6))
                      Row(spacing: 10, children: [
                        IconTile(serviceIconFor(a.key), AppColors.purple, size: 32),
                        Expanded(child: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        PillTag('${a.unused.length} of ${a.enabled}', AppColors.orange),
                      ]),
                  ]),
          );

      usageSection() {
        if (o == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Usage', style: context.appText.sectionHeader.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('How societies use the platform', style: context.appText.timestamp),
                ]),
              ),
              Obx(() => Segmented(
                    items: [for (final r in DashboardController.ranges) '$r days'],
                    selected: DashboardController.ranges.indexOf(controller.range.value),
                    onTap: (i) => controller.range.value = DashboardController.ranges[i],
                  )),
            ]),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              final cards = [
                usageKpi('Active societies (${o.rangeDays} d)', '${o.activeSocieties} of ${o.societies}', Icons.apartment_rounded, AppColors.primary),
                usageKpi('Daily active users', compact(o.dau), Icons.today_outlined, AppColors.teal),
                usageKpi('Monthly active users', compact(o.mau), Icons.calendar_month_outlined, AppColors.purple),
                usageKpi('Monthly recurring revenue', rupees(o.mrrPaise), Icons.payments_outlined, AppColors.success),
              ];
              return Wrap(spacing: 14, runSpacing: 14, children: [for (final k in cards) SizedBox(width: w, child: k)]);
            }),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 1000 ? 2 : 1;
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                SizedBox(width: w, child: chartCard('Active users per day', Icons.show_chart_rounded, o.series['active_users'] ?? const [], AppColors.primary)),
                SizedBox(width: w, child: chartCard('Visitors per day', Icons.directions_walk_rounded, o.series['visitors'] ?? const [], AppColors.success)),
              ]);
            }),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                SizedBox(width: w, child: alertsCard()),
                SizedBox(width: w, child: topCard()),
                SizedBox(width: w, child: unusedCard()),
              ]);
            }),
          ],
        );
      }

      // ── Recent activity timeline ──────────────────────────────────────────
      recentActivity() {
        final rows = controller.recent.toList();
        return panel(
          icon: Icons.history_rounded,
          color: AppColors.primary,
          title: 'Recent activity',
          subtitle: 'The latest changes across the platform',
          trailing: TextButton.icon(onPressed: () => Get.find<MainLayoutController>().select(6), icon: const Icon(Icons.arrow_forward_rounded, size: 16), label: const Text('View all')),
          child: rows.isEmpty
              ? Text('Nothing yet.', style: context.appText.timestamp)
              : Column(children: [
                  for (final (i, r) in rows.indexed)
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        SizedBox(
                          width: 28,
                          child: Column(children: [
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(top: 3),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 3)),
                            ),
                            if (i < rows.length - 1) Expanded(child: Container(width: 2, color: AppColors.dividerLight)),
                          ]),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                              Text(r.summary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Wrap(spacing: 14, runSpacing: 4, children: [
                                if (r.actorName != null) MetaItem(Icons.person_outline_rounded, r.actorName!),
                                if (r.societyName != null) MetaItem(Icons.apartment_rounded, r.societyName!),
                                MetaItem(Icons.schedule_rounded, timeAgo(r.createdAt)),
                              ]),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                ]),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            hero(s, o),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              final cards = [
                kpi('Societies', '${s.societies}', Icons.apartment_rounded, AppColors.primary),
                kpi('Flats', '${s.flats}', Icons.home_work_outlined, AppColors.teal),
                kpi('Residents', '${s.residents}', Icons.people_outline_rounded, AppColors.purple),
                kpi('Society admins', '${s.admins}', Icons.admin_panel_settings_outlined, AppColors.orange),
              ];
              return Wrap(spacing: 14, runSpacing: 14, children: [for (final k in cards) SizedBox(width: w, child: k)]);
            }),
            const SizedBox(height: 14),
            statusBreakdown(s),
            const SizedBox(height: 22),
            usageSection(),
            const SizedBox(height: 22),
            recentActivity(),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }
}
