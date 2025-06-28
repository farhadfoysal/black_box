import 'package:black_box/meter/ui/view/auth/tabs/add_meter_tab_screen.dart';
import 'package:black_box/meter/ui/view/auth/tabs/add_phone_tab_screen.dart';
import 'package:black_box/meter/ui/view/auth/tabs/add_zone_tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/login_provider.dart';
import '../../widgets/exit_widget.dart';
import '../../widgets/tab_bar_app_bar.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const List<Tab> tabs = <Tab>[
    Tab(text: 'Add Phone'),
    Tab(text: 'Add Zone'),
    Tab(text: 'Add Meter'),
  ];

  @override
  Widget build(BuildContext context) {
    LoginProvider provider = Provider.of<LoginProvider>(context, listen: false);
    return DefaultTabController(
      length: tabs.length,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context)!;
          if (provider.changeTab) {
            tabController.animateTo(2);
          }
          return WillPopScope(
            onWillPop: () {
              if (provider.changeTab) {
                provider.changeTabScreen(false);
                return Future(() => true);
              } else if (tabController.index == 0) {
                return showExitPopup(context);
              } else if (tabController.index == 2) {
                tabController.animateTo(1);
                context.read<LoginProvider>().changeTabIndex(2);
                return Future(() => false);
              } else if (tabController.index == 1) {
                tabController.animateTo(0);
                context.read<LoginProvider>().changeTabIndex(1);
                return Future(() => false);
              } else {
                return Future(() => true);
              }
            },
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    TapBarAppBar(
                      tabController: tabController,
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          AddPhoneTabScreen(
                            tabController: tabController,
                            provider: provider,
                          ),
                          AddZoneTabScreen(
                            tabController: tabController,
                            provider: provider,
                          ),
                          AddMeterTabScreen(
                            tabController: tabController,
                            provider: provider,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
