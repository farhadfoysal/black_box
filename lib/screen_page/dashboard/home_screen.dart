import 'package:black_box/modules/menus/home_view.dart';
import 'package:black_box/routes/app_nav_bar.dart';
import 'package:black_box/screen_page/main_panel.dart';
import 'package:flutter/material.dart';

import '../../cores/cores.dart';
import '../../routes/app_router.dart';

class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EduBlackBox',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
    // return MainPanel();
  }


}