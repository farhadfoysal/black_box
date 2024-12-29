import 'package:black_box/components/common/photo_avatar.dart';
import 'package:black_box/cores/cores.dart';
import 'package:black_box/model/user/user.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;

class ProfileView extends StatefulWidget {
  static const String routeName = '/profile';

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: user),
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
            color: context.theme.primaryColor,
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
