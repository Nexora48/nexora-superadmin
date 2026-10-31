import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
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
        const muted = Color(0xFFB6C6E3);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              controller.select(i);
              afterTap?.call();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active ? [BoxShadow(color: AppColors.primary.withAlpha(90), blurRadius: 14, offset: const Offset(0, 5))] : null,
              ),
              child: Row(
                children: [
                  Icon(_icons[i], size: 20, color: active ? AppColors.white : muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      MainLayoutController.titles[i],
                      style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? AppColors.white : muted),
                    ),
                  ),
                  if (active) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.white),
                ],
              ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryLight, AppColors.primary]),
                ),
                child: Text(u?.initials ?? '?', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13)),
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
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF8A9B)),
              ),
            ],
          ),
        );
      });
    }

    // ── Sidebar (desktop) / drawer content ──────────────────────────────────
    sidebar({VoidCallback? afterTap}) {
      return Container(
        width: 260,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2A5C), Color(0xFF0A1B3D)]),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── Brand ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryLight, AppColors.primary]),
                    boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(110), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nexora', style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(6)),
                      child: const Text('SUPERADMIN', style: TextStyle(color: Color(0xFFD5E2FA), fontSize: 9, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 8),
              child: Text('PLATFORM', style: TextStyle(color: Color(0xFF7F95BD), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    if (controller.visible(i)) ...[navItem(i, afterTap: afterTap), const SizedBox(height: 4)],
                ],
              ),
            ),
            const SizedBox(height: 8),
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
          width: 260,
          child: Builder(builder: (ctx) => sidebar(afterTap: () => Navigator.of(ctx).pop())),
        ),
        body: body,
      );
    });
  }
}
