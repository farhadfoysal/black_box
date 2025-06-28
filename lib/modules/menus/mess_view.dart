import 'dart:convert';
import 'dart:io';

import 'package:black_box/components/common/photo_avatar.dart';
import 'package:black_box/cores/cores.dart';
import 'package:black_box/screen_page/signin/sign_in_or_register.dart';
import 'package:black_box/model/user/user.dart';
import 'package:black_box/modules/settings/settings.dart';
import 'package:black_box/modules/tabView/mess_create_view.dart';
import 'package:black_box/modules/tabView/tution_view.dart';
import 'package:black_box/modules/tabView/tutor_view.dart';
import 'package:black_box/routes/app_router.dart';
import 'package:black_box/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/school/school.dart';
import '../../model/school/teacher.dart';
import '../../preference/logout.dart';

class MessView extends StatefulWidget {
  const MessView({super.key});

  @override
  State<StatefulWidget> createState() {
    return MessViewState();
  }
}

class MessViewState extends State<MessView> with SingleTickerProviderStateMixin {
  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  String? sid;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  late User user;
  late TabController _tabController;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;


  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeData();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();

  }

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');


    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? schoolMap = await logout.getSchool(key: 'school_data');


    if (userMap != null) {
      User user_data = User.fromMap(userMap);
      setState(() {
        _user_data = user_data;
        _user = user_data;

      });
    } else {
      print("User map is null");
    }

    if (schoolMap != null) {
      School schoolData = School.fromMap(schoolMap);
      setState(() {
        _user = user;
        school = schoolData;
        sid = school?.sId;
        print(schoolData.sId);
      });
    } else {
      print("School data is null");
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_logged_in');
    String? imagePath = prefs.getString('profile_picture-${_user?.uniqueid!}');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        userName = userData['uname'];
        userPhone = userData['phone'];
        userEmail = userData['email'];
        if (imagePath != null) {
          _selectedImage = File(imagePath);
        }
      });
    }
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserData = prefs.getString('user_logged_in');

    if (savedUserData != null) {
      Map<String, dynamic> userData = jsonDecode(savedUserData);
      setState(() {
        _userName = userData['uname'] ?? 'Tasnim';
      });
    }
  }

  Future<void> _loadUser() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');
    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    User user_data = User.fromMap(userMap!);
    setState(() {
      _user = user;
      _user_data = user_data;
    });
  }

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _onSwipe1(int index) {
    setState(() {
      _currentIndex1 = index;
    });
  }

  void _onSwipe2(int index) {
    setState(() {
      _currentIndex2 = index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> signOut() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully signed out')),
    );
    await AppRouter.logoutUser(context);
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_user != null) _ProfileHeader(user: _user!),
          PreferredSize(
            preferredSize: const Size.fromHeight(30.0),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.black,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black.withOpacity(0.6),
                      tabs: const [
                        Tab(text: 'Tutor'),
                        Tab(text: 'Mess'),
                        Tab(text: 'Tution'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TutorView(),
                MessCreateView(),
                TutionView(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return SafeArea(
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         _ProfileHeader(user: _user!),
  //         PreferredSize(
  //           preferredSize: const Size.fromHeight(30.0),
  //           child: Container(
  //             color: Colors.white,
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: TabBar(
  //                     controller: _tabController,
  //                     indicatorColor: Colors.black, // Tab indicator color
  //                     labelColor: Colors.black, // Selected tab text color set to black
  //                     unselectedLabelColor: Colors.black.withOpacity(0.6), // Unselected tab text color
  //                     tabs: const [
  //                       Tab(text: 'Tutor'),
  //                       Tab(text: 'Mess'),
  //                       Tab(text: 'Tution'),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         SizedBox(height: 2),
  //         // Padding(
  //         //   padding: const EdgeInsets.symmetric(horizontal: 20),
  //         //   child: ElevatedButton(
  //         //     onPressed: signOut,
  //         //     style: ElevatedButton.styleFrom(
  //         //       padding: EdgeInsets.symmetric(vertical: 15),
  //         //       shape: RoundedRectangleBorder(
  //         //         borderRadius: BorderRadius.circular(50),
  //         //       ),
  //         //     ),
  //         //     child: Text(
  //         //       'Sign Out',
  //         //       style: TextStyle(
  //         //         fontSize: 16,
  //         //         fontWeight: FontWeight.bold,
  //         //       ),
  //         //     ),
  //         //   ),
  //         // ),
  //         // SizedBox(height: 20),
  //         // Padding(
  //         //   padding: const EdgeInsets.symmetric(horizontal: 20),
  //         //   child: ElevatedButton(
  //         //     onPressed: () {
  //         //       context.go(Routes.settingsPage);
  //         //     },
  //         //     style: ElevatedButton.styleFrom(
  //         //       padding: EdgeInsets.symmetric(vertical: 15),
  //         //       shape: RoundedRectangleBorder(
  //         //         borderRadius: BorderRadius.circular(50),
  //         //       ),
  //         //     ),
  //         //     child: Text(
  //         //       'Settings',
  //         //       style: TextStyle(
  //         //         fontSize: 16,
  //         //         fontWeight: FontWeight.bold,
  //         //       ),
  //         //     ),
  //         //   ),
  //         // ),
  //         // SizedBox(height: 20),
  //         Expanded(
  //           child: TabBarView(
  //             controller: _tabController,
  //             children: [
  //               TutorView(),
  //               MessCreateView(),
  //               TutionView(),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          XAvatarCircle(
            photoURL:
            "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
            membership: "U",
            progress: 60,
            color: context.themeD.primaryColor,
          ),
          Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.7),
                      child: Text(
                        "Farhad Foysal",
                        style: p20.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.7),
                      child: Text(
                        "mff585855075@gmail.com",
                        style: p14.bold.grey,
                      ),
                    )
                  ],
                ),
              )),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: b.Badge(
                badgeStyle: b.BadgeStyle(
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                  badgeColor: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(13),
                  elevation: 0,
                ),
                badgeContent: Text("7",style: TextStyle(color: Colors.white,fontSize: 12)),
                child: Icon(Icons.notifications,size: 40,),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
