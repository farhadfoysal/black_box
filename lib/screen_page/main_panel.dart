import 'package:black_box/modules/menus/home_view.dart';
import 'package:black_box/modules/menus/profile_app_bar.dart';
import 'package:black_box/modules/menus/profile_view.dart';
import 'package:black_box/modules/menus/schedule_view.dart';
import 'package:black_box/modules/menus/school_view.dart';
import 'package:flutter/material.dart';

import '../cores/cores.dart';
import '../modules/widget/drawer_widget.dart';

class MainPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {

    return _MainPanelState();
    
  }
  
}

class _MainPanelState extends State<MainPanel>{
  int index = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    
    return SafeArea(child: Scaffold(

      appBar: index == 0 ? ProfileAppBar(
        actionIcon: Icons.more_vert,
        onActionPressed: (){},
        appBarbgColor: const Color(0xFF01579B),
      ) : null,
      drawer: const DrawerWidget(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (value) {
          setState(() {
            index = value;
          });
        },
        children: [
          HomeView(),
          ScheduleView(),
          SchoolView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          _pageController.jumpToPage(value);
          setState(() {
            index = value;
          });
        },
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.grey,
        elevation: 3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AppIcons.home),
            activeIcon: Icon(AppIcons.homeAlt),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            activeIcon: Icon(Icons.schedule_outlined),
            label: 'Schedules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            activeIcon: Icon(Icons.school_outlined),
            label: 'School',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.profile),
            activeIcon: Icon(AppIcons.profileAlt),
            label: 'Profile',
          ),
        ],
      ),


    ),);
    
  }
}