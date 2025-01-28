import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityController extends GetxController {
  var isConnected = false.obs; // Observable variable to track connection status
  late StreamSubscription<InternetConnectionStatus> connectionSubscription;

  @override
  void onInit() {
    super.onInit();
    checkInitialConnection();
    startListening();
  }

  @override
  void onClose() {
    stopListening();
    super.onClose();
  }

  // Check the initial internet connection status
  Future<void> checkInitialConnection() async {
    isConnected.value = await InternetConnectionChecker.instance.hasConnection;
  }

  // Start listening to connection changes
  void startListening() {
    connectionSubscription = InternetConnectionChecker.instance.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        isConnected.value = true;
        _showConnectivitySnackBar(isConnected.value);
      } else {
        isConnected.value = false;
        _showConnectivitySnackBar(isConnected.value);
      }
    });
  }

  // Stop listening to connection changes
  void stopListening() {
    connectionSubscription.cancel();
  }

  // Show connectivity snackbar
  void _showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    Get.snackbar(
      "Connectivity Status",
      message,
      backgroundColor: color,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}



// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   Get.put(ConnectivityController()); // Initialize the controller
//   runApp(MyApp());
// }


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'connectivity_controller.dart';
//
// class HomePage extends StatelessWidget {
//   final ConnectivityController connectivityController = Get.find();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Home Page")),
//       body: Center(
//         child: Obx(() {
//           return Text(
//             connectivityController.isConnected.value
//                 ? "You are connected to the internet"
//                 : "You are offline",
//             style: const TextStyle(fontSize: 20),
//           );
//         }),
//       ),
//     );
//   }
// }
