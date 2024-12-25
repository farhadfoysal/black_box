import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:black_box/extra/form/dynamic_form_screen.dart';
import 'package:black_box/extra/quiz/main_screenn.dart';
import 'package:black_box/extra/quiz/quiz_four.dart';
import 'package:black_box/quiz/quiz_main.dart';
import 'package:black_box/quiz/quiz_main_v1.dart';
import 'package:black_box/quiz/quiz_screen.dart';
import 'package:black_box/extra/quiz/quiz_three.dart';
import 'package:black_box/extra/quiz/quiz_two.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/asset_path.dart';
import '../signin/admin_login.dart';
import '../signin/sign_in_screen.dart';

class Splash extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {

    return SplashScreenState();
  }

}

class SplashScreenState extends State<Splash>{
  late Timer _timer;
  bool _isGlowing = false;


  @override
  void initState() {
    super.initState();
    _startGlowAnimation();
    goToScreen();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  void _startGlowAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _isGlowing = !_isGlowing; // Toggle the glow state
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          // appBar: AppBar(
          //   title: const Text("Welcome to Class Organizer"),
          //   centerTitle: true,
          // ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                "assets/images/blueBG.jpg",
                fit: BoxFit.cover,
              ),
              Center(
                child: AvatarGlow(
                  animate: _isGlowing,
                  duration: const Duration(seconds: 2),
                  glowColor: Colors.blue,
                  //endRadius: 140.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        style: BorderStyle.none,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 80.0,
                      child: ClipOval(
                        child: SvgPicture.asset(
                          AssetsPath.logoSvgPath,
                          width: 250,
                        ),
                      ),

                    ),
                  ),
                ),
              ),
              Center(
                child: Lottie.asset(
                  'animation/9.json',
                  width: MediaQuery.sizeOf(context).height,
                  height: MediaQuery.sizeOf(context).width,
                  reverse: true,
                  repeat: true,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ));
  }

  void goToScreen() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final onboarding = prefs.getBool("onboarding")??false;
    final userType = prefs.getString("user_type")??"user";
    Timer(
        const Duration(seconds: 4),
            () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => onboarding ? (userType=="user"?  SignInScreen() :  AdminLogin()) : QuizMainV1())));
  }
}