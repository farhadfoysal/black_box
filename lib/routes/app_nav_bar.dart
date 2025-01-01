import 'package:black_box/modules/menus/schedule_view.dart';
import 'package:black_box/modules/menus/school_view.dart';
import 'package:black_box/modules/widget/drawer_widget.dart';
import 'package:black_box/routes/routes.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:black_box/cores/cores.dart';
import '../components/components.dart';
import '../modules/menus/home_view.dart';
import '../modules/menus/profile_view.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.child,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('AppNavBar'));

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerWidget(),
      body: child,
      bottomNavigationBar: AppBottomBar(
        opacity: .2,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int? index) => _onTap(context, index ?? 0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        elevation: 8,
        hasInk: true, //new, gives a cute ink effect
        items: _navigationItems,
      ),
    );
  }

  static const _navigationItems = <AppBottomBarItem>[
    AppBottomBarItem(
      icon: Icon(AppIcons.home),
      activeIcon: Icon(AppIcons.homeAlt),
      title: Text("Home"),
    ),
    AppBottomBarItem(
      icon: Icon(Icons.schedule),
      activeIcon: Icon(Icons.schedule_outlined),
      title: Text("Schedule"),
    ),
    AppBottomBarItem(
      icon: Icon(Icons.school),
      activeIcon: Icon(Icons.school_outlined),
      title: Text("School"),
    ),
    AppBottomBarItem(
      icon: Icon(Icons.room),
      activeIcon: Icon(Icons.room_outlined),
      title: Text("Mess"),
    ),
    AppBottomBarItem(
      icon: Icon(AppIcons.profile),
      activeIcon: Icon(AppIcons.profileAlt),
      title: Text("Account"),
    )
  ];

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith(Routes.homePage)) {
      return 0;
    }
    if (location.startsWith(Routes.schedulePage)) {
      return 1;
    }
    if (location.startsWith(Routes.schoolPage)) {
      return 2;
    }
    if (location.startsWith(Routes.messPage)) {
      return 3;
    }
    if (location.startsWith(Routes.profilePage)) {
      return 4;
    }

    return 0;
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(Routes.homePage);
        break;
      case 1:
        GoRouter.of(context).go(Routes.schedulePage);
        break;
      case 2:
        GoRouter.of(context).go(Routes.schoolPage);
        break;
      case 3:
        GoRouter.of(context).go(Routes.messPage);
        break;
      case 4:
        GoRouter.of(context).go(Routes.profilePage);
      break;  
    }
  }
}
