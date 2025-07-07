import 'dart:convert';
import 'dart:io';

import 'package:black_box/cores/cores.dart';
import 'package:black_box/screen_page/tutor/tutor_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/common/photo_avatar.dart';
import '../../model/course/teacher.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../screen_page/mess/mess_manager_page.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/tenant': (context) => const TenantManagementPage(),
        '/mess': (context) => const MessManagerPage(),
        '/tuition-tracker': (context) => TutorMainScreen(),
        '/tutor-finder': (context) => const TutorFinderPage(),
        '/roommate-finder': (context) => const RoommateFinderPage(),
        '/tuition-finder': (context) => const TuitionFinderPage(),
      },
    );
  }
}


class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomePage> {
  late User user;
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

  int _currentIndex1 = 0;
  int _currentIndex2 = 0;
  bool isLoading = false;

  final List<DashboardItem> items = [
    DashboardItem(
      title: 'Property Manager',
      icon: MdiIcons.officeBuilding,
      color: Color(0xFF005F73),
      route: '/tenant',
      subtitle: 'Properties & Tenants',
    ),
    DashboardItem(
      title: 'Mess Manager',
      icon: MdiIcons.food,
      color: Colors.orange,
      route: '/mess',
      subtitle: 'Hostel/Dormitory Management',
    ),
    DashboardItem(
      title: 'Tuition Tracker',
      icon: MdiIcons.school,
      color: Colors.green,
      route: '/tuition-tracker',
      subtitle: 'Track Student Payments',
    ),
    DashboardItem(
      title: 'Tutor',
      icon: MdiIcons.schoolOutline,
      color: Colors.purple,
      route: '/tutor-finder',
      subtitle: 'Find Qualified Tutors',
    ),
    DashboardItem(
      title: 'HouseRent',
      icon: MdiIcons.accountGroup,
      color: Colors.red,
      route: '/roommate-finder',
      subtitle: 'Connect with Roommates',
    ),
    DashboardItem(
      title: 'Tuition',
      icon: MdiIcons.magnify,
      color: Colors.teal,
      route: '/tuition-finder',
      subtitle: 'Discover Learning Centers',
    ),
  ];

  void _navigateToFeature(String routeName) {
    Navigator.pushNamed(context, routeName);
  }


  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
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




  // @override
  // Widget build(BuildContext context) {
  //   return SafeArea(
  //     child: SingleChildScrollView(
  //       physics: ClampingScrollPhysics(),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           _ProfileHeader(user: user),
  //           SizedBox(height: 10,),
  //           Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                   'Manage Your Services',
  //                   style: TextStyle(
  //                     fontSize: 24,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Expanded(
  //                   child: GridView.count(
  //                     crossAxisCount: 2,
  //                     mainAxisSpacing: 16,
  //                     crossAxisSpacing: 16,
  //                     childAspectRatio: 1.2,
  //                     children: items.map((item) => _buildDashboardItem(item)).toList(),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: _user!),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage, Your All Services',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 20,
                      fontFamily: 'Lato',
                      color: Color(0xFF005F73),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true, // Ensure GridView adapts to its content height
                    physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: items.map((item) => _buildDashboardItem(item)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDashboardItem(DashboardItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _navigateToFeature(item.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [item.color.withOpacity(0.2), item.color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 40,
                color: item.color,
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: XAvatarCircle(
              photoURL:
              "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
              membership: "U",
              progress: 60,
              color: context.themeD.primaryColor,
            ),
          ),
          Expanded(
              child: Padding(
                padding: EdgeInsets.all(2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.7),
                      child: Text(
                        "${user.uname}",
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 18,
                          fontFamily: 'Lato',
                          color: Color(0xFF005F73),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.7),
                      child: Text(
                        "${user.email}",
                        style: p13.ff.grey,
                      ),
                    )
                  ],
                ),
              )),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(2.0),
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
          // SizedBox(width: 1),
          Padding(
            padding: EdgeInsets.zero,
            child: IconButton(
              icon: Icon(
                Icons.unfold_more,
                size: 30,
                color: context.themeD.primaryColor,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Open Menu',
            ),
          ),


        ],
      ),
    );
  }
}

class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String subtitle;

  DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.subtitle,
  });
}

// Feature Pages
class TenantManagementPage extends StatelessWidget {
  const TenantManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Management')),
      body: const Center(child: Text('Tenant Management Content')),
    );
  }
}

class TutorFinderPage extends StatelessWidget {
  const TutorFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Finder')),
      body: const Center(child: Text('Tutor Finder Content')),
    );
  }
}

class RoommateFinderPage extends StatelessWidget {
  const RoommateFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roommate Finder')),
      body: const Center(child: Text('Roommate Finder Content')),
    );
  }
}

class TuitionFinderPage extends StatelessWidget {
  const TuitionFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuition Finder')),
      body: const Center(child: Text('Tuition Finder Content')),
    );
  }
}