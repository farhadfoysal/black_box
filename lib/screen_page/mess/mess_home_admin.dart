import 'package:black_box/modules/widget/mess_drawer.dart';
import 'package:black_box/screen_page/mess/home_navigation/bazar_list_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/meal_counter_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/mess_fee_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/payment_list_page.dart';
import 'package:black_box/screen_page/mess/home_navigation/personal_details_page.dart';
import 'package:black_box/screen_page/mess/settings/mess_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

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
      appBar: AppBar(
        title: SizedBox(
          height: 35, // Specify a height for the Marquee
          child: Marquee(
            text:
                "MessHome Admin - Developed By - Farhad Foysal",
            style: TextStyle(fontWeight: FontWeight.bold),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 20.0,
            velocity: 100.0,
            pauseAfterRound: Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigates back to the previous page
          },
        ),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
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
