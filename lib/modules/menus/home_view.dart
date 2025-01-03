import 'package:black_box/cores/cores.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import '../../components/common/photo_avatar.dart';
import '../../model/user/user.dart';

class HomeView extends StatefulWidget {

  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
              color: context.theme.primaryColor,
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
                color: context.theme.primaryColor,
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
