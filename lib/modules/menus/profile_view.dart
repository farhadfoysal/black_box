import 'dart:convert';
import 'dart:io';

import 'package:black_box/components/common/photo_avatar.dart';
import 'package:black_box/cores/cores.dart';
import 'package:black_box/screen_page/signin/sign_in_or_register.dart';
import 'package:black_box/model/user/user.dart';
import 'package:black_box/modules/settings/settings.dart';
import 'package:black_box/routes/app_router.dart';
import 'package:black_box/routes/routes.dart';
import 'package:black_box/web/server/client_page.dart';
import 'package:black_box/web/server/server_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../db/database_backup.dart';
import '../../db/database_backup_screen.dart';
import '../../model/mess/mess_main.dart';
import '../../model/mess/mess_user.dart';
import '../../model/school/school.dart';
import '../../model/school/teacher.dart';
import '../../preference/logout.dart';
import '../../web/p2p/client_screen.dart';
import '../../web/p2p/host_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileViewState();
  }
}

class ProfileViewState extends State<ProfileView> {
  late User user;

  // final _auth = FirebaseAuth.instance;
  final _databaseRef = FirebaseDatabase.instance.ref();

  final messName = TextEditingController();
  final messPhone = TextEditingController();
  final messAddress = TextEditingController();
  final messCode = TextEditingController();
  final messPassword = TextEditingController();

  bool isJoining = false; // Toggle between create and join forms
  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  MessUser? messUser, _mess_user_data;
  MessMain? messMain;
  String? sid;
  String? messId;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  late TabController _tabController;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;
  DateTime selectedDate = DateTime.now();
  String? selectedMonthYear;

  @override
  void initState() {
    loadData();
    _loadUserName();
    _initializeData();
    super.initState();
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

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');

    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? schoolMap =
        await logout.getSchool(key: 'school_data');

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

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    // await _loadMessUserData();
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

  void loadData() {
    setState(() {
      user = User(
        uname: "Farhad Foysal",
        pass: '369725',
        phone: '01585855075',
      );
    });
  }

  Future<void> signOut() async {
    // await Logout().logoutUser();
    // await Logout().clearUser(key: "user_logged_in");

    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => SignInOrRegister(),
    //   ),
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully signed out')),
    );
    await AppRouter.logoutUser(context);
    // context.go("/logout");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: user),
            SizedBox(
                height: 20), // Add some space between the header and the button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  signOut();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Settings(),
                    ),
                  );
                  // GoRouter.of(context).go(Routes.settingsPage);
                  // context.push(Routes.settingsPage);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DatabaseBackup(),
                    ),
                  );
                  // GoRouter.of(context).go(Routes.settingsPage);
                  // context.push(Routes.settingsPage);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'BackUp APP DB Files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => Dis(),
                  //   ),
                  // );
                  // GoRouter.of(context).go(Routes.settingsPage);
                  // context.push(Routes.settingsPage);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.wifi),
                    label: const Text('Start as Host'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  ServerPage()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Join as Client'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  ClientPage()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
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
            padding: EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.7),
                  child: Text(
                    "Farhad Foysal",
                    style: p21.bold,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
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
              padding: EdgeInsets.all(18.0),
              child: b.Badge(
                badgeStyle: b.BadgeStyle(
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                  badgeColor: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(13),
                  elevation: 0,
                ),
                badgeContent: Text("7",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                child: Icon(
                  Icons.notifications,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
