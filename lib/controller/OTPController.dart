import 'package:get/get.dart';

class OTPController extends GetxController {
  RxInt countdown = 30.obs;
  RxBool isResendEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    startCountdown();
  }

  void startCountdown() {
    isResendEnabled.value = false;
    countdown.value = 30;
    Future.delayed(Duration(seconds: 1), _startTimer);
  }

  void _startTimer() {
    if (countdown.value > 0) {
      countdown.value--;
      Future.delayed(Duration(seconds: 1), _startTimer);
    } else {
      isResendEnabled.value = true;
    }
  }

  void resendCode() {
    startCountdown();
    // Logic to resend OTP goes here
  }
}
