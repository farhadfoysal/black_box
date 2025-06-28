import 'package:black_box/provider/connectivity_provider.dart';
import 'package:black_box/provider/user/user_provider.dart';
import 'package:black_box/screen_page/splash/splash.dart';
import 'package:black_box/utility/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';

import 'meter/providers/home_provider.dart';
import 'meter/providers/login_provider.dart';

class BlackBoxApp extends StatelessWidget{
  const BlackBoxApp({super.key});

  @override
  Widget build(BuildContext context) {

    final ThemeController themeController = Get.put(ThemeController());
    
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
          ChangeNotifierProvider(create: (_) => LoginProvider()),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
        ],
        child: Obx(
              () => GetMaterialApp(
            title: 'EDU BlackBox',
            debugShowCheckedModeBanner: false,
            theme: themeController.themeData.value, // Observe theme changes
            home: Splash(),
          ),
        ),
    );
  }

}