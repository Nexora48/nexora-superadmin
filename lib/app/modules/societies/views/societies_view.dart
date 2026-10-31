import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/societies_controller.dart';

class SocietiesView extends GetView<SocietiesController> {
  const SocietiesView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Header: title, search, onboard button ───────────────────────────────
    headerView() {
      return Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Societies', style: context.appText.sectionHeader.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Every society on the platform, its size and activity', style: context.appText.timestamp),
            ],
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: controller.searchCtrl,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search name, handle or city',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.dividerLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.dividerLight)),
              ),
            ),
          ),
          if (PlatformAuthService.to.canEdit)
            FilledButton.icon(
              onPressed: controller.openCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Onboard society'),
            ),
        ],
      );
    }

    // ── Summary tiles ───────────────────────────────────────────────────────
    summaryTile(IconData icon, Color color, int index, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            spacing: 12,
            children: [
              IconTile(icon, color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text('${controller.counts[index]}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1))),
                    Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    summaryRow() {
      return LayoutBuilder(builder: (context, c) {
        final tiles = [
          summaryTile(Icons.apartment_rounded, AppColors.primary, 0, 'All societies'),
          summaryTile(Icons.verified_rounded, AppColors.success, 1, 'Active'),
          summaryTile(Icons.hourglass_top_rounded, AppColors.orange, 2, 'On trial'),
          summaryTile(Icons.block_rounded, AppColors.error, 3, 'Suspended'),
        ];
        if (c.maxWidth < 640) {
          return Column(spacing: 10, children: [
            Row(spacing: 10, children: [tiles[0], tiles[1]]),
            Row(spacing: 10, children: [tiles[2], tiles[3]]),
          ]);
        }
        return Row(spacing: 12, children: tiles);
      });
    }

    // ── Status filter ───────────────────────────────────────────────────────
    filterBar() {
      return Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Segmented(
              items: SocietiesController.filters,
              selected: SocietiesController.filters.indexOf(controller.selectedFilter.value),
              onTap: (i) => controller.selectedFilter.value = SocietiesController.filters[i],
            ),
          ));
    }

    // ── Society card row ────────────────────────────────────────────────────
    societyRow(row) {
      final dim = row.isSuspended;
      final accent = switch (row.status) {
        'active' => AppColors.success,
        'trial' => AppColors.primary,
        'suspended' => AppColors.error,
        _ => AppColors.textSecondaryLight,
      };
      final ratio = row.totalServices == 0 ? 0.0 : row.enabledServices / row.totalServices;
      final initial = row.name.isEmpty ? '?' : row.name[0].toUpperCase();
      return SoftCard(
        accent: accent,
        onTap: () => controller.openDetail(row.id),
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dim ? [AppColors.errorLight, AppColors.error.withAlpha(60)] : [AppColors.primaryLighter, AppColors.primary.withAlpha(70)],
                  ),
                ),
                child: Text(initial, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: dim ? AppColors.error : AppColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Wrap(spacing: 12, children: [
                      MetaItem(Icons.tag_rounded, row.slug),
                      if (row.city.isNotEmpty) MetaItem(Icons.place_outlined, row.city),
                    ]),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width >= 1100)
                Builder(builder: (context) {
                Widget stat(IconData icon, String v, String l) => SizedBox(
                      width: 96,
                      child: Row(
                        spacing: 8,
                        children: [
                          Icon(icon, size: 17, color: AppColors.textSecondaryLight),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              Text(l, style: context.appText.timestamp),
                            ],
                          ),
                        ],
                      ),
                    );
                return Row(children: [
                  stat(Icons.meeting_room_outlined, '${row.flats}', 'flats'),
                  stat(Icons.people_outline_rounded, '${row.residents}', 'residents'),
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Text('${row.enabledServices}/${row.totalServices} services', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(minHeight: 6, value: ratio, backgroundColor: AppColors.dividerLight, valueColor: AlwaysStoppedAnimation(accent)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 110,
                    child: Row(
                      spacing: 6,
                      children: [
                        const Icon(Icons.login_rounded, size: 15, color: AppColors.textSecondaryLight),
                        Expanded(child: Text(timeAgo(row.lastSignIn), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ]);
              }),
              statusChip(row.status),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      );
    }

    // ── Pagination ──────────────────────────────────────────────────────────
    pagination() {
      return Obx(() {
        final page = controller.currentPage.value;
        final total = controller.total.value;
        final start = total == 0 ? 0 : (page - 1) * SocietiesController.perPage + 1;
        final end = (page * SocietiesController.perPage) > total ? total : page * SocietiesController.perPage;
        return Row(
          children: [
            Text('Showing $start–$end of $total', style: context.appText.timestamp),
            const Spacer(),
            IconButton(onPressed: page > 1 ? () => controller.goToPage(page - 1) : null, icon: const Icon(Icons.chevron_left_rounded)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(22), borderRadius: BorderRadius.circular(10)),
              child: Text('$page / ${controller.totalPages}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            IconButton(onPressed: page < controller.totalPages ? () => controller.goToPage(page + 1) : null, icon: const Icon(Icons.chevron_right_rounded)),
          ],
        );
      });
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerView(),
          const SizedBox(height: 16),
          summaryRow(),
          const SizedBox(height: 16),
          filterBar(),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.error.value.isNotEmpty) {
                return stateMessage(context,
                    icon: Icons.cloud_off_rounded, title: 'Could not load societies', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
              }
              if (controller.items.isEmpty) {
                return stateMessage(context,
                    icon: Icons.apartment_rounded,
                    title: 'No societies found',
                    subtitle: 'Try a different search or filter.',
                    actionLabel: PlatformAuthService.to.canEdit ? 'Onboard society' : null,
                    onAction: controller.openCreate);
              }
              return ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (_, i) => societyRow(controller.items[i]),
              );
            }),
          ),
          const SizedBox(height: 8),
          pagination(),
        ],
      ),
    );
  }
}
