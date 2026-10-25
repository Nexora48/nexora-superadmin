import 'package:get/get.dart';

import '../modules/audit_logs/bindings/audit_logs_binding.dart';
import '../modules/billing/bindings/billing_binding.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/main_layout/bindings/main_layout_binding.dart';
import '../modules/main_layout/views/main_layout_view.dart';
import '../modules/mfa/bindings/mfa_binding.dart';
import '../modules/mfa/views/mfa_view.dart';
import '../modules/services/bindings/services_binding.dart';
import '../modules/society_create/bindings/society_create_binding.dart';
import '../modules/society_create/views/society_create_view.dart';
import '../modules/society_detail/bindings/society_detail_binding.dart';
import '../modules/society_detail/views/society_detail_view.dart';
import '../modules/societies/bindings/societies_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.login;

  static final routes = [
    GetPage(name: _Paths.login, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(name: _Paths.mfa, page: () => const MfaView(), binding: MfaBinding()),
    GetPage(
      name: _Paths.mainLayout,
      page: () => const MainLayoutView(),
      bindings: [
        MainLayoutBinding(),
        DashboardBinding(),
        SocietiesBinding(),
        ServicesBinding(),
        BillingBinding(),
        AuditLogsBinding(),
      ],
    ),
    GetPage(name: _Paths.societyDetail, page: () => const SocietyDetailView(), binding: SocietyDetailBinding()),
    GetPage(name: _Paths.societyCreate, page: () => const SocietyCreateView(), binding: SocietyCreateBinding()),
  ];
}
