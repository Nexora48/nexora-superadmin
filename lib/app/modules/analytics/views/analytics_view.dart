import 'package:nexora_superadmin/app/core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/m10_models.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Range switch ────────────────────────────────────────────────────────
    rangeChips() => Obx(
      () => Segmented(
        items: [for (final r in AnalyticsController.ranges) '$r days'],
        selected: AnalyticsController.ranges.indexOf(controller.range.value),
        onTap: (i) => controller.range.value = AnalyticsController.ranges[i],
      ),
    );

    String fmt(num v) => controller.metric.value == 'collected_paise' ? rupees(v.round()) : compact(v);

    // ── Summary tiles from the shown series ─────────────────────────────────
    summaryTile(IconData icon, Color color, String value, String label, {String? note}) {
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
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (note != null) Text(note, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
    }

    summaryRow() {
      return Obx(() {
        final pts = controller.series.toList();
        final total = controller.total;
        final avg = pts.isEmpty ? 0 : total / pts.length;
        Point? peak;
        for (final p in pts) {
          if (peak == null || p.value > peak.value) peak = p;
        }
        final tiles = [
          summaryTile(Icons.functions_rounded, AppColors.primary, fmt(total), 'Total in ${controller.range.value} days'),
          summaryTile(Icons.timeline_rounded, AppColors.teal, fmt(avg), 'Daily average'),
          summaryTile(Icons.bolt_rounded, AppColors.orange, peak == null ? '—' : fmt(peak.value), 'Peak day', note: peak == null ? null : shortDay(peak.day)),
          summaryTile(Icons.apartment_rounded, AppColors.purple, '${controller.top.length}', 'Active societies'),
        ];
        return LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 700) {
            return Column(spacing: 10, children: [Row(spacing: 10, children: [tiles[0], tiles[1]]), Row(spacing: 10, children: [tiles[2], tiles[3]])]);
          }
          return Row(spacing: 12, children: tiles);
        });
      });
    }

    // ── Metric explorer ─────────────────────────────────────────────────────
    explorer() {
      return cardBox(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(spacing: 12, children: [
              const IconTile(Icons.insights_rounded, AppColors.primary, size: 38),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Metric explorer', style: context.appText.sectionHeader),
                  Text('Pick a metric and a society to see its daily trend', style: context.appText.timestamp),
                ]),
              ),
              FilledButton.tonalIcon(
                onPressed: controller.exportSeries,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Save CSV'),
              ),
            ]),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 250,
                  child: Obx(
                    () => AppDropdown<String>(
                      initialValue: controller.metric.value,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Metric', isDense: true, prefixIcon: Icon(Icons.show_chart_rounded, size: 20)),
                      items: [for (final m in controller.metrics) DropdownMenuItem(value: m.key, child: Text(m.name))],
                      onChanged: (v) => controller.metric.value = v ?? controller.metric.value,
                    ),
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: Obx(
                    () => AppDropdown<String>(
                      initialValue: controller.societyId.value,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Society', isDense: true, prefixIcon: Icon(Icons.apartment_rounded, size: 20)),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Whole platform')),
                        for (final s in controller.societies) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => controller.societyId.value = v ?? '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primary.withAlpha(16), AppColors.primary.withAlpha(3)]),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                        '${controller.metricName(controller.metric.value)} · last ${controller.range.value} days',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      )),
                  const SizedBox(height: 8),
                  Obx(
                    () => trendChart(
                      controller.series.toList(),
                      height: 240,
                      format: controller.metric.value == 'collected_paise' ? (n) => rupees(n) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Top societies ───────────────────────────────────────────────────────
    topList() {
      const medal = [Color(0xFFF5B301), Color(0xFF9AA5B1), Color(0xFFCD7F32)];
      return cardBox(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final maxV = controller.top.isEmpty ? 1 : controller.top.map((r) => r.value).reduce((a, b) => a > b ? a : b);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Row(spacing: 12, children: [
                const IconTile(Icons.emoji_events_rounded, AppColors.orange, size: 38),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Top societies', style: context.appText.sectionHeader),
                    Text(controller.metricName(controller.metric.value), style: context.appText.timestamp),
                  ]),
                ),
              ]),
              if (controller.top.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No activity in this period.', style: context.appText.timestamp)),
              for (final (i, r) in controller.top.indexed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Row(spacing: 10, children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < 3 ? medal[i] : AppColors.backgroundLight,
                        ),
                        child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: i < 3 ? AppColors.white : AppColors.textSecondaryLight)),
                      ),
                      Expanded(child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                      Text(fmt(r.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: maxV == 0 ? 0 : r.value / maxV,
                        backgroundColor: AppColors.dividerLight,
                        valueColor: AlwaysStoppedAnimation(i < 3 ? medal[i] : AppColors.primary),
                      ),
                    ),
                  ],
                ),
            ],
          );
        }),
      );
    }

    // ── Adoption ────────────────────────────────────────────────────────────
    unusedDialog(ServiceAdoption a) {
      Get.dialog(
        dialogShell(
          context,
          title: '${a.name}: enabled but unused',
          subtitle: '${a.unused.length} ${a.unused.length == 1 ? 'society' : 'societies'} · last ${controller.range.value} days',
          icon: serviceIconFor(a.key),
          color: AppColors.orange,
          maxWidth: 480,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('These societies have the service on but recorded nothing in the last ${controller.range.value} days.', style: context.appText.timestamp),
              const SizedBox(height: 12),
              for (final s in a.unused)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(14)),
                  child: Row(spacing: 12, children: [
                    const IconTile(Icons.apartment_rounded, AppColors.primary, size: 38),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Wrap(spacing: 12, children: [
                          if (s.city.isNotEmpty) MetaItem(Icons.place_outlined, s.city),
                          MetaItem(Icons.meeting_room_outlined, '${s.units} flats'),
                        ]),
                      ]),
                    ),
                  ]),
                ),
            ],
          ),
          actions: [FilledButton(onPressed: Get.back, child: const Text('Close'))],
        ),
      );
    }

    adoptionTable() {
      return cardBox(
        padding: const EdgeInsets.all(20),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(spacing: 12, children: [
                const IconTile(Icons.donut_large_rounded, AppColors.teal, size: 38),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Service adoption', style: context.appText.sectionHeader),
                    Text('Enabled = switched on for the society · Used = at least one record in the last ${controller.range.value} days', style: context.appText.timestamp),
                  ]),
                ),
              ]),
              for (final a in controller.adoption)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    spacing: 14,
                    children: [
                      IconTile(serviceIconFor(a.key), a.adoptionPc >= 50 ? AppColors.success : AppColors.orange),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                          Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Wrap(spacing: 14, children: [
                            MetaItem(Icons.toggle_on_outlined, '${a.enabled} enabled'),
                            MetaItem(Icons.bolt_rounded, '${a.used} used'),
                          ]),
                        ]),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(spacing: 10, children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: a.adoptionPc / 100,
                                backgroundColor: AppColors.dividerLight,
                                valueColor: AlwaysStoppedAnimation(a.adoptionPc >= 50 ? AppColors.success : AppColors.warning),
                              ),
                            ),
                          ),
                          SizedBox(width: 42, child: Text('${a.adoptionPc}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        ]),
                      ),
                      SizedBox(
                        width: 120,
                        child: a.unused.isEmpty
                            ? const Align(alignment: Alignment.centerRight, child: PillTag('All in use', AppColors.success))
                            : FilledButton.tonalIcon(
                                onPressed: () => unusedDialog(a),
                                icon: const Icon(Icons.visibility_off_outlined, size: 15),
                                label: Text('${a.unused.length} unused', style: const TextStyle(fontSize: 12)),
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty && controller.adoption.isEmpty) {
        return stateMessage(
          context,
          icon: Icons.cloud_off_rounded,
          title: 'Could not load analytics',
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
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Analytics', style: context.appText.sectionHeader.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
                    Text('How societies use the platform', style: context.appText.timestamp),
                  ],
                ),
                rangeChips(),
              ],
            ),
            const SizedBox(height: 16),
            summaryRow(),
            const SizedBox(height: 14),
            noticeBar(controller.notice),
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: explorer()),
                      const SizedBox(width: 14),
                      Expanded(child: topList()),
                    ],
                  );
                }
                return Column(
                  children: [
                    explorer(),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: topList()),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            adoptionTable(),
          ],
        ),
      );
    });
  }
}
