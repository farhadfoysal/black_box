import 'package:flutter/material.dart';
import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  late StreamSubscription<InternetConnectionStatus> _connectionSubscription;

  ConnectivityProvider() {
    checkInitialConnection();
    startListening();
  }

  // Check the initial connection status
  Future<void> checkInitialConnection() async {
    _isConnected = await InternetConnectionChecker.instance.hasConnection;
    notifyListeners();
  }

  // Start listening to connection changes
  void startListening() {
    _connectionSubscription = InternetConnectionChecker.instance.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        _isConnected = true;
      } else {
        _isConnected = false;
      }
      notifyListeners();
    });
  }

  // Stop listening to connection changes
  void stopListening() {
    _connectionSubscription.cancel();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'connectivity_provider.dart';
//
// void main() {
//   runApp(
//     ChangeNotifierProvider(
//       create: (context) => ConnectivityProvider(),
//       child: MyApp(),
//     ),
//   );
// }



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'connectivity_provider.dart';
//
// class HomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Home Page")),
//       body: Center(
//         child: Consumer<ConnectivityProvider>(
//           builder: (context, connectivityProvider, child) {
//             return Text(
//               connectivityProvider.isConnected
//                   ? "You are connected to the internet"
//                   : "You are offline",
//               style: const TextStyle(fontSize: 20),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
