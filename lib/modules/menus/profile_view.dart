import 'package:black_box/components/common/photo_avatar.dart';
import 'package:black_box/cores/cores.dart';
import 'package:black_box/extra/test/sign_in_or_register.dart';
import 'package:black_box/model/user/user.dart';
import 'package:black_box/modules/settings/settings.dart';
import 'package:black_box/routes/app_router.dart';
import 'package:black_box/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:go_router/go_router.dart';

import '../../preference/logout.dart';

class ProfileView extends StatefulWidget {


  const ProfileView({super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileViewState();
  }
}

class ProfileViewState extends State<ProfileView> {
  late User user;

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
            SizedBox(height: 20), // Add some space between the header and the button
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
