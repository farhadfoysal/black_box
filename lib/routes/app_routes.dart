import 'package:black_box/screen_page/signin/sign_in_or_register.dart';
import 'package:black_box/modules/menus/mess_view.dart';
import 'package:black_box/modules/menus/schedule_view.dart';
import 'package:black_box/modules/menus/school_view.dart';
import 'package:black_box/modules/settings/settings.dart';
import 'package:black_box/routes/routes.dart';
import 'package:black_box/screen_page/mess/mess_home_admin.dart';
import 'package:black_box/screen_page/mess/mess_home_employee.dart';
import 'package:black_box/screen_page/mess/mess_home_member.dart';
import 'package:black_box/screen_page/signin/login.dart';
import 'package:black_box/screen_page/signup/Register.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../modules/menus/home_view.dart';
import '../modules/menus/profile_view.dart';

class AppRoutes {

  static final mainMenuRoutes = <RouteBase>[
    GoRoute(
      name: Routes.homePage,
      path: Routes.homePage,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const HomeView(),
          transitionsBuilder: (_, animation, __, child) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      name: Routes.schedulePage,
      path: Routes.schedulePage,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: const ScheduleView(),
          transitionsBuilder: (_, animation, __, child) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      name: Routes.schoolPage,
      path: Routes.schoolPage,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: const SchoolView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.profilePage,
      path: Routes.profilePage,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: const ProfileView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.messPage,
      path: Routes.messPage,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: const MessView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
  ].toList(growable: false);
  static final login_logoutRoutes = <RouteBase>[
    GoRoute(
      name: Routes.logout,
      path: Routes.logout,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: SignInOrRegister(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.settingsPage,
      path: Routes.settingsPage,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: Settings(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.start,
      path: Routes.start,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: SignInOrRegister(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.login,
      path: Routes.login,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: Login(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.register,
      path: Routes.register,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: Register(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.messAdmin,
      path: Routes.messAdmin,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: MessHomeAdmin(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.messEmployee,
      path: Routes.messEmployee,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: MessHomeEmployee(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: Routes.messMember,
      path: Routes.messMember,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: MessHomeMember(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
  ];
}