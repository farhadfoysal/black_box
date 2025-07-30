import 'dart:convert';
import 'dart:io';

import 'package:black_box/cores/cores.dart';
import 'package:black_box/extra/quiz/exam_attempt_page.dart';
import 'package:black_box/extra/quiz/exam_attempt_page_main.dart';
import 'package:black_box/extra/quiz/quiz_four.dart';
import 'package:black_box/extra/quiz/quiz_three.dart';
import 'package:black_box/extra/quiz/quiz_two.dart';
import 'package:black_box/quiz/quiz_screen.dart';
import 'package:black_box/screen_page/exam/exam_list.dart';
import 'package:black_box/screen_page/tutor/tutor_main_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:google_fonts/google_fonts.dart';
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
        '/to-let': (context) => const TenantManagementPage(),
        '/mess': (context) => const MessManagerPage(),
        '/tuition-tracker': (context) => TutorMainScreen(),
        '/tutor-finder': (context) => const TutorFinderPage(),
        '/roommate-finder': (context) => const RoommateFinderPage(),
        '/tuition-finder': (context) => const TuitionFinderPage(),
        '/budget-tracker': (context) =>  ExamAttemptPage(),
        '/bazar-list': (context) =>  ExamAttemptPagee(),
        '/course-finder': (context) => const TuitionFinderPage(),
        '/exam-management': (context) => ExamListPage(),
        '/seba-manager': (context) => const TuitionFinderPage(),
        '/hisab-manager': (context) => const TuitionFinderPage(),
        '/vocabulary-manager': (context) => const TuitionFinderPage(),
        '/calculation-manager': (context) => const TuitionFinderPage(),
      },
    );
  }
}


class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomePage> with TickerProviderStateMixin{

  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;

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
      title: 'Property-Manager',
      icon: MdiIcons.officeBuilding,
      color: Color(0xFF005F73),
      route: '/tenant',
      subtitle: 'Properties & Tenants',
    ),
    DashboardItem(
      title: 'To~Let',
      icon: MdiIcons.officeBuilding,
      color: Color(0xFF005F73),
      route: '/to-let',
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
      color: Colors.orangeAccent,
      route: '/tuition-finder',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Budget Tracker',
      icon: MdiIcons.magnify,
      color: Colors.teal,
      route: '/budget-tracker',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Bazar List',
      icon: MdiIcons.magnify,
      color: Colors.cyan,
      route: '/bazar-list',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Courses',
      icon: MdiIcons.magnify,
      color: Colors.deepPurpleAccent,
      route: '/course-finder',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Exam Management',
      icon: MdiIcons.magnify,
      color: Colors.blue,
      route: '/exam-management',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Seba Manger',
      icon: MdiIcons.magnify,
      color: Colors.teal,
      route: '/seba-manager',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Hisab Manager',
      icon: MdiIcons.magnify,
      color: Colors.pinkAccent,
      route: '/hisab-manager',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Calculation',
      icon: MdiIcons.magnify,
      color: Colors.red,
      route: '/calculation-manager',
      subtitle: 'Discover Learning Centers',
    ),
    DashboardItem(
      title: 'Vocabulary',
      icon: MdiIcons.magnify,
      color: Colors.yellow,
      route: '/vocabulary-manager',
      subtitle: 'Discover Learning Centers',
    ),
  ];

  void _navigateToFeature(String routeName) {
    Navigator.pushNamed(context, routeName);
  }


  @override
  void initState() {
    super.initState();
    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Automatically pulse continuously

    // Initialize animation
    _notificationAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _notificationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadUserName();
    _initializeData();
  }

  @override
  void dispose() {
    _notificationController.dispose();


    super.dispose();
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
  //   if (_user == null) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //
  //   // Calculate the number of rows needed (4 items per row)
  //   final rowCount = (items.length / 4).ceil();
  //   // Calculate height based on row count (100px per row + spacing)
  //   final gridHeight = rowCount * 100 + (rowCount - 1) * 8;
  //
  //   return Scaffold(
  //     backgroundColor: Colors.grey[50],
  //     body: SafeArea(
  //       child: SingleChildScrollView(
  //         physics: ClampingScrollPhysics(),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             _buildGlassProfileHeader(context),
  //             const SizedBox(height: 2),
  //             Padding(
  //               padding: const EdgeInsets.all(16.0),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Manage Your All Services',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),
  //                   SizedBox(
  //                     height: gridHeight.toDouble(),
  //                     child: GridView.builder(
  //                       shrinkWrap: true,
  //                       physics: const NeverScrollableScrollPhysics(),
  //                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                         crossAxisCount: 4,
  //                         mainAxisSpacing: 8,
  //                         crossAxisSpacing: 8,
  //                         childAspectRatio: 0.9,
  //                       ),
  //                       itemCount: items.length,
  //                       itemBuilder: (context, index) {
  //                         return Transform.translate(
  //                           offset: index.isEven
  //                               ? const Offset(0, 20)
  //                               : Offset.zero,
  //                           child: _buildHexItem(items[index]),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGlassProfileHeader(context),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Your All Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return Transform.translate(
                          offset: index.isEven
                              ? const Offset(0, 20)
                              : Offset.zero,
                          child: _buildHexItem(items[index]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _adjustColor(Color color, int amount) {
    return Color.fromARGB(
      color.alpha,
      (color.red + amount).clamp(0, 255),
      (color.green + amount).clamp(0, 255),
      (color.blue + amount).clamp(0, 255),
    );
  }

  Widget _buildHexItem(DashboardItem item) {
    return ClipPath(
      clipper: HexagonClipper(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToFeature(item.route),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withOpacity(0.2),
                  item.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: item.color,
                ),
                const SizedBox(height: 8),
                Text(
                  item.title.split(' ').first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   if (_user == null) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //   return SafeArea(
  //     child: SingleChildScrollView(
  //       physics: ClampingScrollPhysics(),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           _buildGlassProfileHeader(context),
  //           // _ProfileHeader(user: _user!),
  //           SizedBox(height: 10),
  //           Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                   'Manage, Your All Services',
  //                   style: TextStyle(
  //                     decoration: TextDecoration.none,
  //                     fontSize: 20,
  //                     fontFamily: 'Lato',
  //                     color: Color(0xFF005F73),
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 GridView.count(
  //                   shrinkWrap: true, // Ensure GridView adapts to its content height
  //                   physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
  //                   crossAxisCount: 2,
  //                   mainAxisSpacing: 16,
  //                   crossAxisSpacing: 16,
  //                   childAspectRatio: 1.2,
  //                   children: items.map((item) => _buildDashboardItem(item)).toList(),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


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



  Widget _buildGlassProfileHeader(BuildContext context) {
    final user = _user;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.4),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with animated border
            InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          const Color(0xFF6A11CB),
                          const Color(0xFF2575FC),
                          const Color(0xFF6A11CB),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        // child: Image.network(
                        //   "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
                        //   fit: BoxFit.cover,
                        //   loadingBuilder: (context, child, loadingProgress) {
                        //     if (loadingProgress == null) return child;
                        //     return CircularProgressIndicator(
                        //       value: loadingProgress.expectedTotalBytes != null
                        //           ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        //           : null,
                        //     );
                        //   },
                        //   errorBuilder: (context, error, stackTrace) => Icon(Icons.person),
                        // ),
                        child: CachedNetworkImage(
                          imageUrl: "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      final clampedValue = value.clamp(0.0, 1.0);
                      return CircularProgressIndicator(
                        value: clampedValue,
                        strokeWidth: 2,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.5)),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // User info with subtle animation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      final clampedValue = value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(20 * (1 - clampedValue), 0),
                        child: Opacity(
                          opacity: clampedValue,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      user?.uname ?? "User Name",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "user@example.com",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),

            // Notification icon with pulse animation
            Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () {
                    _notificationController
                      ..reset()
                      ..forward();
                  },
                  child: MouseRegion(
                    onEnter: (_) => _notificationController.forward(),
                    onExit: (_) => _notificationController.reverse(),
                    child: AnimatedBuilder(
                      animation: _notificationAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _notificationAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2575FC).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              color: const Color(0xFF4A5568),
                              iconSize: 26,
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 6,
                  child: ScaleTransition(
                    scale: _notificationAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE53E3E),
                            const Color(0xFFF56565),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        "7",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}