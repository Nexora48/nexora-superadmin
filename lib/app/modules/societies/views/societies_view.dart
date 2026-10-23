import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/societies_controller.dart';

class SocietiesView extends GetView<SocietiesController> {
  const SocietiesView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Header: title, search, onboard button ───────────────────────────────
    headerView() {
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Societies', style: context.appText.sectionHeader.copyWith(fontSize: 20)),
          SizedBox(
            width: 280,
            child: TextField(
              controller: controller.searchCtrl,
              onChanged: controller.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search name, handle or city',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
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

    // ── Status filter chips ─────────────────────────────────────────────────
    filterBar() {
      return Obx(() => Wrap(
            spacing: 8,
            children: [
              for (final f in SocietiesController.filters)
                ChoiceChip(
                  label: Text(f),
                  selected: controller.selectedFilter.value == f,
                  onSelected: (_) => controller.selectedFilter.value = f,
                ),
            ],
          ));
    }

    // ── Society card row ────────────────────────────────────────────────────
    societyRow(row) {
      final dim = row.isSuspended;
      return InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => controller.openDetail(row.id),
        child: cardBox(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: dim ? AppColors.errorLight : AppColors.primaryLighter,
                child: Icon(Icons.apartment_rounded, color: dim ? AppColors.error : AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('${row.slug}${row.city.isEmpty ? '' : ' · ${row.city}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.appText.timestamp),
                  ],
                ),
              ),
              LayoutBuilder(builder: (context, _) {
                final wide = MediaQuery.of(context).size.width >= 1100;
                if (!wide) return const SizedBox.shrink();
                Widget stat(String v, String l) => SizedBox(
                      width: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(l, style: context.appText.timestamp),
                        ],
                      ),
                    );
                return Row(children: [
                  stat('${row.flats}', 'flats'),
                  stat('${row.residents}', 'residents'),
                  stat('${row.enabledServices}/${row.totalServices}', 'services'),
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeAgo(row.lastSignIn), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('last sign-in', style: context.appText.timestamp),
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
            Text('$page / ${controller.totalPages}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 12),
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
              return ListView.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
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
