import 'dart:async';

import 'package:black_box/modules/menus/home_view.dart';
import 'package:black_box/modules/widget/profile_app_bar.dart';
import 'package:black_box/modules/menus/profile_view.dart';
import 'package:black_box/modules/menus/schedule_view.dart';
import 'package:black_box/modules/menus/school_view.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../cores/cores.dart';
import '../modules/widget/drawer_widget.dart';
import '../web/internet_connectivity.dart';

class MainPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {

    return _MainPanelState();
    
  }
  
}

class _MainPanelState extends State<MainPanel>{
  int index = 0;
  final PageController _pageController = PageController();

  bool isConnected = false;
  late StreamSubscription subscription;
  final internetChecker = InternetConnectivity();
  StreamSubscription<InternetConnectionStatus>? connectionSubscription;

  bool loading = false;

  @override
  void dispose() {
    stopListening();
    connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }


  Future<void> _initializeApp() async {

    startListening();
    checkConnection();
    subscription = internetChecker.checkConnectionContinuously((status) {

      isConnected = status;

    });
  }
  void checkConnection() async {
    bool result = await internetChecker.hasInternetConnection();
    setState(() {
      isConnected = result;
    });
  }

  StreamSubscription<InternetConnectionStatus> checkConnectionContinuously() {
    return InternetConnectionChecker.instance.onStatusChange.listen((InternetConnectionStatus status) {
      if (status == InternetConnectionStatus.connected) {
        isConnected = true;
        showConnectivitySnackBar(isConnected);
        print('Connected to the internet ff');

      } else {
        isConnected = false;
        showConnectivitySnackBar(isConnected);
        print('Disconnected from the internet ff');
        // _loadSchoolData();
      }
    });
  }

  void showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }


  void startListening() {
    connectionSubscription = checkConnectionContinuously();
  }

  void stopListening() {
    connectionSubscription?.cancel();
  }

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