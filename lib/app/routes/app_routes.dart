part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const login = _Paths.login;
  static const mfa = _Paths.mfa;
  static const mainLayout = _Paths.mainLayout;
  static const societyDetail = _Paths.societyDetail;
  static const societyCreate = _Paths.societyCreate;
}

abstract class _Paths {
  _Paths._();
  static const login = '/login';
  static const mfa = '/mfa';
  static const mainLayout = '/main';
  static const societyDetail = '/society';
  static const societyCreate = '/society-new';
}
