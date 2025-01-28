import 'dart:async';

import 'package:black_box/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../../screen_page/signup/Register.dart';
import '../../screen_page/signin/login.dart';
import '../../web/internet_connectivity.dart';

class SignInOrRegister extends StatefulWidget {

  @override
  _SignInOrRegisterState createState() => _SignInOrRegisterState();
}

class _SignInOrRegisterState extends State<SignInOrRegister> {

  bool isConnected = false;
  late StreamSubscription subscription;
  final internetChecker = InternetConnectivity();
  StreamSubscription<InternetConnectionStatus>? connectionSubscription;

  bool loading = false;

  @override
  void dispose() {
    stopListening();
    connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }


  Future<void> _initializeApp() async {

    startListening();
    checkConnection();
    subscription = internetChecker.checkConnectionContinuously((status) {

      isConnected = status;

    });
  }
  void checkConnection() async {
    bool result = await internetChecker.hasInternetConnection();
    setState(() {
      isConnected = result;
    });
  }

  StreamSubscription<InternetConnectionStatus> checkConnectionContinuously() {
    return InternetConnectionChecker.instance.onStatusChange.listen((InternetConnectionStatus status) {
      if (status == InternetConnectionStatus.connected) {
        isConnected = true;
        showConnectivitySnackBar(isConnected);
        print('Connected to the internet ff');

      } else {
        isConnected = false;
        showConnectivitySnackBar(isConnected);
        print('Disconnected from the internet ff');
        // _loadSchoolData();
      }
    });
  }

  void showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }


  void startListening() {
    connectionSubscription = checkConnectionContinuously();
  }

  void stopListening() {
    connectionSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // This line is used to make the notification bar transparent
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Image.asset(
            // TODO update background image according to your brand
            'assets/background.jpg',
            fit: BoxFit.fill,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(.9),
                      Colors.black.withOpacity(.1),
                    ])),
          ),
          Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 27.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        // TODO update this
                        'Join Mr BookWorm!',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: () {
                          final snackbar = SnackBar(
                            content: Text('Please try email login'),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                              },
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackbar);
                        },
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 20),
                                height: 22,
                                width: 22,
                                child: Image.asset('assets/google_logo.png'),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Google',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      InkWell(
                        onTap: () {
                          final snackbar = SnackBar(
                            content: Text('Please try email login'),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                              },
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackbar);
                        },
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          height: 50,
                          decoration: BoxDecoration(
                              color: Color(0xff3B5998),
                              borderRadius: BorderRadius.circular(50)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Quiz Button
                              InkWell(
                                onTap: () {
                                  final snackbar = SnackBar(
                                    content: Text('Quiz button pressed'),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                      },
                                    ),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackbar);
                                },
                                child: Container(
                                  width: 130, // Adjust width as needed
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 1, vertical: 1),
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Quiz',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10), // Space between buttons
                              // Admin Button
                              InkWell(
                                onTap: () {
                                  final snackbar = SnackBar(
                                    content: Text('Admin button pressed'),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                      },
                                    ),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackbar);
                                },
                                child: Container(
                                  width: 130, // Adjust width as needed
                                  margin: EdgeInsets.all(1),
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                          // context.go(Routes.login);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(50)),
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          child: Center(
                              child: Text(
                                'Login',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              )),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50)),
                        margin: EdgeInsets.symmetric(horizontal: 30),
                        child: Center(
                            child: Text(
                              "Don't have an account?",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            )),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Register()),
                          );
                        },
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50)),
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          child: Center(
                              child: Text(
                                "Create account",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )),
                        ),
                      ),
                    ],
                  ),
                );
              })
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../../screen_page/signup/Register.dart';
// import '../../screen_page/signin/login.dart';
//
// class SignInOrRegister extends StatefulWidget {
//   @override
//   _SignInOrRegisterState createState() => _SignInOrRegisterState();
// }
//
// class _SignInOrRegisterState extends State<SignInOrRegister> {
//   @override
//   Widget build(BuildContext context) {
//     // This line is used to make the notification bar transparent
//     SystemChrome.setSystemUIOverlayStyle(
//         SystemUiOverlayStyle(statusBarColor: Colors.transparent));
//
//     return Scaffold(
//       body: Stack(
//         children: <Widget>[
//           Image.asset(
//             // TODO update background image according to your brand
//             'assets/background.jpg',
//             fit: BoxFit.fill,
//             height: double.infinity,
//             width: double.infinity,
//           ),
//           Container(
//             decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                     colors: [
//                       Colors.black.withOpacity(.9),
//                       Colors.black.withOpacity(.1),
//                     ])),
//           ),
//           Builder(
//               builder: (BuildContext context) {
//                 return Padding(
//                   padding: EdgeInsets.only(bottom: 60),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: <Widget>[
//                       Text(
//                         'Welcome',
//                         style: TextStyle(
//                           fontSize: 27.0,
//                           color: Colors.white,
//                         ),
//                       ),
//                       SizedBox(
//                         height: 4,
//                       ),
//                       Text(
//                         // TODO update this
//                         'Join Mr BookWorm!',
//                         style: TextStyle(
//                           fontSize: 16.0,
//                           color: Colors.white,
//                         ),
//                       ),
//                       SizedBox(
//                         height: 20,
//                       ),
//                       InkWell(
//                         onTap: () {
//                           final snackbar = SnackBar(
//                             content: Text('Please try email login'),
//                             action: SnackBarAction(
//                               label: 'OK',
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context)
//                                     .hideCurrentSnackBar();
//                               },
//                             ),
//                           );
//                           ScaffoldMessenger.of(context).showSnackBar(snackbar);
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
//                           padding: EdgeInsets.symmetric(vertical: 10),
//                           height: 50,
//                           decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(50)),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: <Widget>[
//                               Container(
//                                 margin: EdgeInsets.only(left: 20),
//                                 height: 22,
//                                 width: 22,
//                                 child: Image.asset('assets/google_logo.png'),
//                               ),
//                               SizedBox(width: 10),
//                               Text(
//                                 'Google',
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                         height: 10,
//                       ),
//                       InkWell(
//                         onTap: () {
//                           final snackbar = SnackBar(
//                             content: Text('Please try email login'),
//                             action: SnackBarAction(
//                               label: 'OK',
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context)
//                                     .hideCurrentSnackBar();
//                               },
//                             ),
//                           );
//                           ScaffoldMessenger.of(context).showSnackBar(snackbar);
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
//                           padding: EdgeInsets.symmetric(vertical: 10),
//                           height: 50,
//                           decoration: BoxDecoration(
//                               color: Color(0xff3B5998),
//                               borderRadius: BorderRadius.circular(50)),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               // Quiz Button
//                               InkWell(
//                                 onTap: () {
//                                   final snackbar = SnackBar(
//                                     content: Text('Quiz button pressed'),
//                                     action: SnackBarAction(
//                                       label: 'OK',
//                                       onPressed: () {
//                                         ScaffoldMessenger.of(context)
//                                             .hideCurrentSnackBar();
//                                       },
//                                     ),
//                                   );
//                                   ScaffoldMessenger.of(context)
//                                       .showSnackBar(snackbar);
//                                 },
//                                 child: Container(
//                                   width: 130, // Adjust width as needed
//                                   margin: EdgeInsets.symmetric(
//                                       horizontal: 5, vertical: 5),
//                                   padding: EdgeInsets.symmetric(vertical: 10),
//                                   height: 50,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blueAccent,
//                                     borderRadius: BorderRadius.circular(50),
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       'Quiz',
//                                       style: TextStyle(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               // Admin Button
//                               InkWell(
//                                 onTap: () {
//                                   final snackbar = SnackBar(
//                                     content: Text('Admin button pressed'),
//                                     action: SnackBarAction(
//                                       label: 'OK',
//                                       onPressed: () {
//                                         ScaffoldMessenger.of(context)
//                                             .hideCurrentSnackBar();
//                                       },
//                                     ),
//                                   );
//                                   ScaffoldMessenger.of(context)
//                                       .showSnackBar(snackbar);
//                                 },
//                                 child: Container(
//                                   width: 130, // Adjust width as needed
//                                   margin: EdgeInsets.symmetric(
//                                       horizontal: 5, vertical: 5),
//                                   padding: EdgeInsets.symmetric(vertical: 10),
//                                   height: 50,
//                                   decoration: BoxDecoration(
//                                     color: Colors.deepOrange,
//                                     borderRadius: BorderRadius.circular(50),
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       'Admin',
//                                       style: TextStyle(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//
//                         ),
//                       ),
//                       SizedBox(
//                         height: 20,
//                       ),
//                       InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => Login()),
//                           );
//                         },
//                         child: Container(
//                           height: 50,
//                           decoration: BoxDecoration(
//                               border: Border.all(color: Colors.white),
//                               borderRadius: BorderRadius.circular(50)),
//                           margin: EdgeInsets.symmetric(horizontal: 30),
//                           child: Center(
//                               child: Text(
//                                 'Login',
//                                 style: TextStyle(fontSize: 16, color: Colors.white),
//                               )),
//                         ),
//                       ),
//                       SizedBox(
//                         height: 10,
//                       ),
//                       Container(
//                         height: 50,
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(50)),
//                         margin: EdgeInsets.symmetric(horizontal: 30),
//                         child: Center(
//                             child: Text(
//                               "Don't have an account?",
//                               style: TextStyle(fontSize: 16, color: Colors.white),
//                             )),
//                       ),
//                       InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => Register()),
//                           );
//                         },
//                         child: Container(
//                           height: 30,
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(50)),
//                           margin: EdgeInsets.symmetric(horizontal: 30),
//                           child: Center(
//                               child: Text(
//                                 "Create account",
//                                 style: TextStyle(
//                                     fontSize: 16,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               )),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               })
//         ],
//       ),
//     );
//   }
// }
