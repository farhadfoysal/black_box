import 'package:black_box/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extra/test/sign_in_or_register.dart';
import '../modules/menus/home_view.dart';
import '../preference/logout.dart';
import 'app_nav_bar.dart';
import 'app_routes.dart';

class AppRouter {
  static GoRouter get router => _router;
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static GlobalKey<NavigatorState> get mainMenuNavigatorKey =>
      _mainMenuNavigatorKey;
  static GlobalKey<NavigatorState> get loginNavigatorKey => _loginNavigatorKey;

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _mainMenuNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'main-menu');
  static final GlobalKey<NavigatorState> _loginNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'login-logout');

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.start,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _mainMenuNavigatorKey,
        builder: (_, __, child) {
          return AppNavBar(child: child);
        },
        routes: <RouteBase>[
          ...AppRoutes.mainMenuRoutes,
        ],
      ),
      ...AppRoutes.login_logoutRoutes,

    ],
  );

  static Future<void> logoutUser(BuildContext context) async {
    await Logout().logoutUser();
    await Logout().logoutMessUser();
    await Logout().clearUser(key: "user_logged_in");
    await Logout().clearMessUser(key: "mess_user_logged_in");
    await Logout().clearMess(key: "mess_data");

    context.goNamed(Routes.logout);
  }
}
