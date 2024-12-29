import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../modules/menus/home_view.dart';
import '../modules/menus/profile_view.dart';

class AppRoutes {

  static final mainMenuRoutes = <RouteBase>[
    GoRoute(
      name: HomeView.routeName,
      path: HomeView.routeName,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          child: const HomeView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: ProfileView.routeName,
      path: ProfileView.routeName,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          child: const ProfileView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
  ].toList(growable: false);

}