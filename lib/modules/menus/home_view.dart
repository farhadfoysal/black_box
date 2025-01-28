import 'package:black_box/cores/cores.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../components/common/photo_avatar.dart';
import '../../model/user/user.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manager Blackbox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/tenant': (context) => const TenantManagementPage(),
        '/mess': (context) => const MessManagerPage(),
        '/tuition-tracker': (context) => const TuitionTrackerPage(),
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

  final List<DashboardItem> items = [
    DashboardItem(
      title: 'Tenant Management',
      icon: MdiIcons.officeBuilding,
      color: Colors.blue,
      route: '/tenant',
      subtitle: 'Manage Properties & Tenants',
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
      title: 'Tutor Finder',
      icon: MdiIcons.beach,
      color: Colors.purple,
      route: '/tutor-finder',
      subtitle: 'Find Qualified Tutors',
    ),
    DashboardItem(
      title: 'Roommate Finder',
      icon: MdiIcons.accountGroup,
      color: Colors.red,
      route: '/roommate-finder',
      subtitle: 'Connect with Roommates',
    ),
    DashboardItem(
      title: 'Tuition Finder',
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
    loadData();
    super.initState();
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
    return SafeArea(
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: user),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage All Services',
                    style: TextStyle(
                      fontSize: 24,
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
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
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
                        "Farhad Foysal Zibran",
                        style: p18.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.7),
                      child: Text(
                        "mff585855075@gmail.com",
                        style: p13.bold.grey,
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

class MessManagerPage extends StatelessWidget {
  const MessManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Manager')),
      body: const Center(child: Text('Mess Management Content')),
    );
  }
}

class TuitionTrackerPage extends StatelessWidget {
  const TuitionTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuition Tracker')),
      body: const Center(child: Text('Tuition Tracking Content')),
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