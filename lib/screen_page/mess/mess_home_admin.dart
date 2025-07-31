import 'package:black_box/modules/widget/mess_drawer.dart';
import 'package:black_box/screen_page/mess/home_navigation/bazar_list_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/meal_counter_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/mess_fee_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/payment_list_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/personal_details_page.dart';
import 'package:black_box/screen_page/mess/settings/mess_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';

class MessHomeAdmin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MessHomeAdminState();
  }
}

class MessHomeAdminState extends State<MessHomeAdmin> {
  int index = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   systemOverlayStyle: SystemUiOverlayStyle(
      //     statusBarColor: Colors.transparent,
      //     statusBarIconBrightness: Brightness.dark,
      //   ),
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back_ios_new_rounded,
      //         color: Colors.indigo.shade800),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: Container(
      //     height: 40,
      //     padding: EdgeInsets.symmetric(horizontal: 8),
      //     decoration: BoxDecoration(
      //       color: Colors.indigo.shade50,
      //       borderRadius: BorderRadius.circular(20),
      //       border: Border.all(
      //         color: Colors.indigo.shade100,
      //         width: 1.5,
      //       ),
      //     ),
      //     child: Row(
      //       children: [
      //         Container(
      //           padding: EdgeInsets.all(6),
      //           decoration: BoxDecoration(
      //             shape: BoxShape.circle,
      //             color: Colors.indigo.shade100,
      //           ),
      //           child: Icon(Icons.code_rounded,
      //               size: 16,
      //               color: Colors.indigo.shade800),
      //         ),
      //         SizedBox(width: 8),
      //         Expanded(
      //           child: Shimmer.fromColors(
      //             baseColor: Colors.indigo.shade800,
      //             highlightColor: Colors.indigo.shade400,
      //             child: Marquee(
      //               text: "MessHome Admin - Developed By Farhad Foysal",
      //               style: TextStyle(
      //                 fontSize: 14,
      //                 fontWeight: FontWeight.w600,
      //                 color: Colors.indigo.shade800,
      //               ),
      //               scrollAxis: Axis.horizontal,
      //               blankSpace: 40.0,
      //               velocity: 60.0,
      //               pauseAfterRound: Duration(seconds: 2),
      //               startPadding: 20.0,
      //               accelerationDuration: Duration(seconds: 1),
      //               decelerationDuration: Duration(milliseconds: 500),
      //               fadingEdgeStartFraction: 0.1,
      //               fadingEdgeEndFraction: 0.1,
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      //   // actions: [
      //   //   Container(
      //   //     margin: EdgeInsets.only(right: 8),
      //   //     decoration: BoxDecoration(
      //   //       shape: BoxShape.circle,
      //   //       border: Border.all(
      //   //         color: Colors.indigo.shade100,
      //   //         width: 1.5,
      //   //       ),
      //   //     ),
      //   //     child: IconButton(
      //   //       icon: Icon(Icons.menu_rounded,
      //   //           color: Colors.indigo.shade800),
      //   //       onPressed: () => Scaffold.of(context).openDrawer(),
      //   //     ),
      //   //   ),
      //   // ],
      //   actions: [
      //     Builder(
      //       builder: (context) => Container(
      //         margin: EdgeInsets.only(right: 8),
      //         decoration: BoxDecoration(
      //           shape: BoxShape.circle,
      //           border: Border.all(
      //             color: Colors.indigo.shade100,
      //             width: 1.5,
      //           ),
      //         ),
      //         child: IconButton(
      //           icon: Icon(Icons.menu_rounded,
      //               color: Colors.indigo.shade800),
      //           onPressed: () {
      //             Scaffold.of(context).openDrawer();
      //           },
      //         ),
      //       ),
      //     ),
      //   ],
      //   flexibleSpace: Container(
      //     decoration: BoxDecoration(
      //       gradient: LinearGradient(
      //         colors: [
      //           Colors.white.withOpacity(0.96),
      //           Colors.white.withOpacity(0.96),
      //         ],
      //         begin: Alignment.topCenter,
      //         end: Alignment.bottomCenter,
      //       ),
      //       boxShadow: [
      //         BoxShadow(
      //           color: Colors.black12,
      //           blurRadius: 10,
      //           spreadRadius: 0,
      //           offset: Offset(0, 2),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      // appBar: AppBar(
      //   title: SizedBox(
      //     height: 35, // Specify a height for the Marquee
      //     child: Marquee(
      //       text:
      //           "MessHome Admin - Developed By - Farhad Foysal",
      //       style: TextStyle(fontWeight: FontWeight.bold),
      //       scrollAxis: Axis.horizontal,
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       blankSpace: 20.0,
      //       velocity: 100.0,
      //       pauseAfterRound: Duration(seconds: 1),
      //       startPadding: 10.0,
      //       accelerationDuration: Duration(seconds: 1),
      //       accelerationCurve: Curves.linear,
      //       decelerationDuration: Duration(milliseconds: 500),
      //       decelerationCurve: Curves.easeOut,
      //     ),
      //   ),
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back),
      //     onPressed: () {
      //       Navigator.pop(context); // Navigates back to the previous page
      //     },
      //   ),
      //   actions: <Widget>[
      //     Builder(
      //       builder: (context) => IconButton(
      //         icon: Icon(Icons.menu),
      //         onPressed: () {
      //           Scaffold.of(context).openDrawer();
      //         },
      //       ),
      //     ),
      //   ],
      // ),
      drawer: MessDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (value) {
          setState(() {
            index = value;
          });
        },
        children: [
          MessDashboardPage(),
          BazarListPage(),
          PaymentListPage(),
          MessFeePage(),
          PersonalDetailsPage(),
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_outlined),
            label: 'BaZar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_rounded),
            label: 'Fees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),


    );
  }
}
