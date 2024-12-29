import 'dart:async';

import 'package:black_box/db/local/database_manager.dart';
import 'package:black_box/quiz/quiz_main_v1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../preference/logout.dart';
import '../../web/internet_connectivity.dart';
import '../dashboard/home_screen.dart';
import '../signup/Register.dart';
import 'package:black_box/model/user/user.dart' as local;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final _auth = FirebaseAuth.instance;
  final _databaseRef = FirebaseDatabase.instance.ref();
  bool _isLoading = true;


  // Controllers for user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Key for the form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool signInApiInProgress = false;
  bool showPassWord = false;
  String? selectedRole;
  int uType = 0;

  bool isConnected = false;
  late StreamSubscription subscription;
  final internetChecker = InternetConnectivity();
  StreamSubscription<InternetConnectionStatus>? connectionSubscription;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    _initializeApp();
  }
  Future<void> _initializeApp() async {
    // await checkLoginStatus();

    startListening();
    checkConnection();
    subscription = internetChecker.checkConnectionContinuously((status) {
      setState(() {
        isConnected = status;
      });
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
        print('Connected to the internet');

      } else {
        isConnected = false;
        print('Disconnected from the internet');
        // _loadSchoolData();
      }
    });
  }

  void startListening() {
    connectionSubscription = checkConnectionContinuously();
  }

  void stopListening() {
    connectionSubscription?.cancel();
  }

  void clearfield() {
    emailController.clear();
    passwordController.clear();
  }

  void checkLoginStatus() async {

    bool isLoggedIn = await Logout().isLoggedIn();

    if (isLoggedIn) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } else {
      // User is not logged in, stay on the sign-in screen
    }
  }

  void signIn()  {

    setState(() {
      loading = true;
    });
    Future.delayed(Duration(seconds: 2), () async{
      signInApiInProgress = true;
      if (mounted) {
        setState(() {});
      }


      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if(selectedRole=="4"){
        uType = 4;
      }else if(selectedRole=="3") {
        uType = 3;
      }else
      {
        uType = 2;
      }

      if(await InternetConnectionChecker.instance.hasConnection){

        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);

          User? firebaseUser = userCredential.user;

          if (firebaseUser != null) {
            DatabaseReference userRef = FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(firebaseUser.uid);

            final snapshot = await userRef.get();

            if (snapshot.exists) {
              Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
              local.User user = local.User.fromMap(userData);

              if (mounted) {
                if(selectedRole=="4"){
                  uType = 4;
                  if(uType==user.utype){

                    await Logout().setLoggedIn(true);
                    await Logout().setUserType(uType);
                    await Logout().saveUser(user.toMap(), key: "user_logged_in");
                    await Logout().saveUserDetails(user, key: "user_data");

                    setState(() {
                      loading = false;
                    });

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ),
                    );
                  }else{
                    showSnackBarMsg(context, 'You are the wrong guy!');
                  }
                }
                else if(selectedRole=="3"){
                  uType = 3;
                  if(uType==user.utype){

                    await Logout().setLoggedIn(true);
                    await Logout().setUserType(uType);
                    await Logout().saveUser(user.toMap(), key: "user_logged_in");
                    await Logout().saveUserDetails(user, key: "user_data");

                    setState(() {
                      loading = false;
                    });

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ),
                    );
                  }else{
                    showSnackBarMsg(context, 'You are the wrong guy!');
                  }
                }else{
                  uType = 2;
                  if(uType==user.utype){
                    await Logout().setLoggedIn(true);
                    await Logout().setUserType(uType);
                    await Logout().saveUser(user.toMap(), key: "user_logged_in");
                    await Logout().saveUserDetails(user, key: "user_data");

                    setState(() {
                      loading = false;
                    });

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuizMainV1(),
                      ),
                    );
                  }else{
                    showSnackBarMsg(context, 'You are the wrong guy!');
                  }
                }
              }
            } else {
              showSnackBarMsg(context, 'User data not found!');
            }
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            showSnackBarMsg(context, 'No user found for that email.');
          } else if (e.code == 'wrong-password') {
            showSnackBarMsg(context, 'Wrong password provided.');
          } else {
            showSnackBarMsg(context, e.message ?? 'An error occurred.');
          }
        } finally {
          setState(() {
            signInApiInProgress = false;
          });
        }

      }else{
        // User? user = await DatabaseHelper().checkUserByPhone(email, password);

        local.User? user = await DatabaseManager().checkUserLogin(email, password,uType);

        signInApiInProgress = true;
        if (mounted) {
          setState(() {});
        }

        if (user != null) {

          if (mounted) {
            if(selectedRole=="4"){
              uType = 4;
              if(uType==user.utype){
                await Logout().setLoggedIn(true);
                await Logout().setUserType(uType);
                await Logout().saveUser(user.toMap(), key: "user_logged_in");
                await Logout().saveUserDetails(user,key: "user_data");
                setState(() {
                  loading = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(),
                  ),
                );
              }else{
                showSnackBarMsg(context, 'You are the wrong guy!!');
              }
            }
            else if(selectedRole=="3"){
              uType = 3;
              if(uType==user.utype){
                await Logout().setLoggedIn(true);
                await Logout().setUserType(uType);
                await Logout().saveUser(user.toMap(), key: "user_logged_in");
                await Logout().saveUserDetails(user,key: "user_data");
                setState(() {
                  loading = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(),
                  ),
                );
              }else{
                showSnackBarMsg(context, 'You are the wrong guy!!');
              }
            }else{
              uType = 2;
              if(uType==user.utype){
                await Logout().setLoggedIn(true);
                await Logout().setUserType(uType);
                await Logout().saveUser(user.toMap(), key: "user_logged_in");
                await Logout().saveUserDetails(user,key: "user_data");
                setState(() {
                  loading = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuizMainV1(),
                  ),
                );
              }else{
                showSnackBarMsg(context, 'You are the wrong guy!');
              }
            }


          }
        } else {

          if (mounted) {
            showSnackBarMsg(context, 'Email or password is not correct!');
          }
        }

      }
    });



  }

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background Image
          Image.asset(
            'assets/background.jpg', // TODO: Update the asset path
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Welcome Text
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 27.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Login to Mr BookWorm!', // TODO: Update this text
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Email Input
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.6),
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.white70),
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Password Input
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.6),
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.vpn_key, color: Colors.white70),
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: loading ? CircularProgressIndicator(color: Colors.white)
                            :  ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {

                              signIn();

                              print(
                                  "Email: ${emailController.text}, Password: ${passwordController.text}");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Don't Have an Account
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      // Create Account Link
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Register()),
                          );
                        },
                        child: Text(
                          "Create account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
