import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utility/player/MP4_like_lottie_animation.dart';

class IntroOne extends StatelessWidget {
  const IntroOne({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child:
                MP4LikeLottieAnimation(assetPath: 'animation/(15).mp4'),

                // Lottie.asset(
                //   'animation/ (9).json',
                //   height: 300,
                //   reverse: true,
                //   repeat: true,
                //   fit: BoxFit.cover,
                // ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "MultiTask Management",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "BlackBox helps manage Properties, Mess, Tuition, Tutor, Student academic routines efficiently. "
                      "This section of the app also includes a Property Management System "
                      "that lets users manage property listings, tenant details, and rental schedules seamlessly.",
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ));
  }
}
