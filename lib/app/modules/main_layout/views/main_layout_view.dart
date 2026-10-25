import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../services/platform_auth_service.dart';
import '../../analytics/views/analytics_view.dart';
import '../../audit_logs/views/audit_logs_view.dart';
import '../../billing/views/billing_view.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../plans/views/plans_view.dart';
import '../../services/views/services_view.dart';
import '../../societies/views/societies_view.dart';
import '../../staff/views/staff_view.dart';
import '../../system/views/system_view.dart';
import '../controllers/main_layout_controller.dart';

class MainLayoutView extends GetView<MainLayoutController> {
  const MainLayoutView({super.key});

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.apartment_rounded,
    Icons.workspace_premium_outlined,
    Icons.insights_rounded,
    Icons.toggle_on_outlined,
    Icons.payments_outlined,
    Icons.history_rounded,
    Icons.groups_2_outlined,
    Icons.monitor_heart_outlined,
  ];
  static const _pages = <Widget>[DashboardView(), SocietiesView(), PlansView(), AnalyticsView(), ServicesView(), BillingView(), AuditLogsView(), StaffView(), SystemView()];

  @override
  Widget build(BuildContext context) {
    final auth = PlatformAuthService.to;

    // ── Nav item ────────────────────────────────────────────────────────────
    navItem(int i, {VoidCallback? afterTap}) {
      return Obx(() {
        final active = controller.currentIndex.value == i;
        return InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: () {
            controller.select(i);
            afterTap?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                Icon(_icons[i], size: 19, color: active ? AppColors.white : const Color(0xFFB6C6E3)),
                const SizedBox(width: 12),
                Text(
                  MainLayoutController.titles[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.white : const Color(0xFFB6C6E3),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    // ── Signed-in user card ─────────────────────────────────────────────────
    userCard() {
      return Obx(() {
        final u = auth.user.value;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: AppRadius.mdAll),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary,
                child: Text(u?.initials ?? '?', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u?.fullName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(u?.roleLabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB6C6E3), fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: controller.logout,
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB6C6E3)),
              ),
            ],
          ),
        );
      });
    }

    // ── Sidebar (desktop) / drawer content ──────────────────────────────────
    sidebar({VoidCallback? afterTap}) {
      return Container(
        width: 250,
        color: const Color(0xFF0F2A5C),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.mdAll),
                  child: const Icon(Icons.shield_rounded, color: AppColors.white, size: 19),
                ),
                const SizedBox(width: 10),
                const Text('Nexora', style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 44),
              child: Text('SUPERADMIN', style: TextStyle(color: Color(0xFFB6C6E3), fontSize: 10, letterSpacing: 1.4)),
            ),
            const SizedBox(height: 28),
            for (var i = 0; i < _pages.length; i++)
              if (controller.visible(i)) ...[navItem(i, afterTap: afterTap), const SizedBox(height: 4)],
            const Spacer(),
            userCard(),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 1000;
      final body = Obx(() => IndexedStack(index: controller.currentIndex.value, children: _pages));
      if (desktop) {
        return Scaffold(
          backgroundColor: context.colors.background,
          body: Row(children: [sidebar(), Expanded(child: body)]),
        );
      }
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Obx(() => Text(MainLayoutController.titles[controller.currentIndex.value])),
        ),
        drawer: Drawer(
          width: 250,
          child: Builder(builder: (ctx) => sidebar(afterTap: () => Navigator.of(ctx).pop())),
        ),
        body: body,
      );
    });
  }
}
