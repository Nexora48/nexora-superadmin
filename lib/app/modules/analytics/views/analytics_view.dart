import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/m10_models.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Range chips ─────────────────────────────────────────────────────────
    rangeChips() => Obx(
      () => Wrap(
        spacing: 8,
        children: [
          for (final r in AnalyticsController.ranges)
            ChoiceChip(
              label: Text('$r days'),
              selected: controller.range.value == r,
              onSelected: (_) => controller.range.value = r,
            ),
        ],
      ),
    );

    // ── Metric explorer ─────────────────────────────────────────────────────
    explorer() {
      return cardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metric explorer', style: context.appText.sectionHeader),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.metric.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Metric',
                        isDense: true,
                      ),
                      items: [
                        for (final m in controller.metrics)
                          DropdownMenuItem(value: m.key, child: Text(m.name)),
                      ],
                      onChanged: (v) => controller.metric.value =
                          v ?? controller.metric.value,
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.societyId.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Society',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Whole platform'),
                        ),
                        for (final s in controller.societies)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => controller.societyId.value = v ?? '',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.exportSeries,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Save CSV'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Obx(
              () => Text(
                '${controller.metricName(controller.metric.value)} · total ${controller.metric.value == 'collected_paise' ? rupees(controller.total) : compact(controller.total)} in ${controller.range.value} days',
                style: context.appText.timestamp,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => trendChart(
                controller.series.toList(),
                height: 220,
                format: controller.metric.value == 'collected_paise'
                    ? (n) => rupees(n)
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    // ── Top societies ───────────────────────────────────────────────────────
    topList() {
      return cardBox(
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top societies · ${controller.metricName(controller.metric.value)}',
                style: context.appText.sectionHeader,
              ),
              const SizedBox(height: 8),
              if (controller.top.isEmpty)
                Text(
                  'No activity in this period.',
                  style: context.appText.timestamp,
                ),
              for (final (i, r) in controller.top.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${i + 1}',
                          style: context.appText.timestamp,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        controller.metric.value == 'collected_paise'
                            ? rupees(r.value)
                            : compact(r.value),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // ── Adoption table ──────────────────────────────────────────────────────
    unusedDialog(ServiceAdoption a) {
      Get.dialog(
        dialogShell(
          context,
          title: '${a.name}: enabled but unused (${a.unused.length})',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These societies have the service on but recorded nothing in the last ${controller.range.value} days.',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 8),
              for (final s in a.unused)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name),
                  subtitle: Text('${s.city} · ${s.units} flats'),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Close')),
          ],
        ),
      );
    }

    adoptionTable() {
      return cardBox(
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service adoption', style: context.appText.sectionHeader),
              Text(
                'Enabled = switched on for the society. Used = at least one record in the last ${controller.range.value} days.',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Enabled',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Used',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Adoption',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 110),
                ],
              ),
              const Divider(),
              for (final a in controller.adoption)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          a.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Text('${a.enabled}')),
                      Expanded(child: Text('${a.used}')),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 7,
                                  value: a.adoptionPc / 100,
                                  backgroundColor: AppColors.dividerLight,
                                  valueColor: AlwaysStoppedAnimation(
                                    a.adoptionPc >= 50
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${a.adoptionPc}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: a.unused.isEmpty
                            ? const SizedBox.shrink()
                            : TextButton(
                                onPressed: () => unusedDialog(a),
                                child: Text(
                                  '${a.unused.length} unused',
                                  style: const TextStyle(fontSize: 12),
                                ),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Analytics',
                    style: context.appText.sectionHeader.copyWith(fontSize: 20),
                  ),
                ),
                rangeChips(),
              ],
            ),
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
