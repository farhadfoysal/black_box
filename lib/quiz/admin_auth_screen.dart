import 'dart:async';
import 'package:black_box/quiz/AdminQuizManagerPage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../controller/OTPController.dart';
import '../cores/cores.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final TextEditingController _otpController = TextEditingController();
  final OTPController otpController = Get.put(OTPController());

  StreamController<ErrorAnimationType> errorController = StreamController<ErrorAnimationType>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Lottie animation
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Lottie.asset(
                        'animation/welcome1.json',  // Put your lottie file here
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "PIN Verification",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "A 6-digit verification code has been sent to your email address.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Pin Code Field
                  PinCodeTextField(
                    length: 6,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 55,
                      fieldWidth: 45,
                      activeColor: Colors.white,
                      selectedColor: Colors.deepPurpleAccent,
                      inactiveColor: Colors.white30,
                      activeFillColor: Colors.white,
                      selectedFillColor: Colors.deepPurple.shade100,
                      inactiveFillColor: Colors.white10,
                    ),
                    cursorColor: Colors.deepPurple,
                    keyboardType: TextInputType.number,
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    errorAnimationController: errorController,
                    controller: _otpController,
                    appContext: context,
                  ),
                  const SizedBox(height: 24),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTabVerifyButton,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Verify",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Countdown Timer
                  Obx(() => RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      text: "This code will expire in ",
                      children: [
                        TextSpan(
                          text: '${otpController.countdown.value}s',
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 10),

                  // Resend Code Button
                  Obx(
                        () => TextButton(
                      onPressed: otpController.isResendEnabled.value ? otpController.resendCode : null,
                      child: Text(
                        "Resend Code",
                        style: TextStyle(
                          color: otpController.isResendEnabled.value
                              ? Colors.white
                              : Colors.white24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onTabVerifyButton() {
    String otp = _otpController.text;

    if (otp.length == 6) {
      bool isOtpValid = verifyOtp(otp);

      if (isOtpValid) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminQuizManagerPage(),
          ),
        );
      } else {
        errorController.add(ErrorAnimationType.shake);
      }
    } else {
      errorController.add(ErrorAnimationType.shake);
    }
  }

  bool verifyOtp(String otp) {
    return otp == "369725"; // Replace this with your real OTP validation logic
  }

  @override
  void dispose() {
    if (mounted) {
      _otpController.clear(); // Clear the controller if still mounted
    }
    _otpController.dispose();
    errorController.close();
    super.dispose();
  }

}

// Elegant background with soft gradient
class BackgroundWidget extends StatelessWidget {
  final Widget child;

  const BackgroundWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6D5DF6), Color(0xFF4626D3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
