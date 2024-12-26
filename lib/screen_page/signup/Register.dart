import 'dart:async';

import 'package:black_box/db/local/database_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:uuid/uuid.dart';

import '../../db/local/database_helper.dart';
import '../../preference/logout.dart';
import '../../style/color/app_color.dart';
import '../../utility/app_constant.dart';
import '../../utility/unique.dart';
import '../../web/internet_connectivity.dart';
import '../dashboard/home_screen.dart';
import '../onboarding/get_start.dart';
import '../signin/login.dart';
import 'package:black_box/model/user/user.dart' as local;

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  final _auth = FirebaseAuth.instance;
  final _databaseRef = FirebaseDatabase.instance.ref();
  bool _isLoading = true;

  // Controllers for input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController autoCompleteController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  bool showPassWord = false;
  bool registrationInProgress = false;
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
    nameController.clear();
    phoneController.clear();
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

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    stopListening();
    subscription.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // Set transparent status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image
          Image.asset(
            'assets/background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 100),
                  Text(
                    'Welcome',
                    style: TextStyle(fontSize: 27.0, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Join With Us, Mr BookWorm!',
                    style: TextStyle(fontSize: 16.0, color: Colors.white70),
                  ),
                  SizedBox(height: 32),
                  // Input fields
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.email_sharp, color: Colors.white70),
                      suffixIcon: IconButton(
                        onPressed: () {
                          showPassWord = !showPassWord;
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        icon: Icon(Icons.email, color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value?.trim().isEmpty ?? true) {
                        return "Enter Your Email ";
                      }
                      if (AppConstant.emailRegExp.hasMatch(value!) == false) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.text,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Name",
                      hintStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.verified_user, color: Colors.white70),
                      suffixIcon: IconButton(
                        onPressed: () {
                          showPassWord = !showPassWord;
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        icon: Icon(Icons.verified_user, color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value?.trim().isEmpty ?? true) {
                        return "Enter Your Full Name ";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Mobile Number",
                      hintStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.mobile_screen_share, color: Colors.white70),
                      suffixIcon: IconButton(
                        onPressed: () {
                          showPassWord = !showPassWord;
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        icon: Icon(Icons.phone, color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value?.trim().isEmpty ?? true) {
                        return "Enter Your Phone Number ";
                      }
                      if (AppConstant.phoneRegExp.hasMatch(value!) ==
                          false) {
                        return "Enter a valid mobile number";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: showPassWord == false,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        onPressed: () {
                          showPassWord = !showPassWord;
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        icon: Icon(showPassWord
                            ? Icons.visibility
                            : Icons.visibility_off, color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value?.trim().isEmpty ?? true) {
                        return "Enter Your Password ";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: showPassWord == false,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
                      hintStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        onPressed: () {
                          showPassWord = !showPassWord;
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        icon: Icon(showPassWord
                            ? Icons.visibility
                            : Icons.visibility_off, color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value?.trim().isEmpty ?? true) {
                        return "Confirm Your Password ";
                      }
                      if (value != confirmPasswordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),
                  DropdownButtonFormField<String>(
                    style: TextStyle(color: Colors.blue),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.verified_user, color: Colors.white70),
                      hintText: "Sign up as",
                      hintStyle: TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '3', child: Text('Student',)),
                      DropdownMenuItem(value: '2', child: Text('Teacher')),
                      DropdownMenuItem(value: '4', child: Text('User')),
                      // Add more departments as needed
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value?.trim().isEmpty ?? true) {
                        return "Select Any Option ";
                      }
                      // if (value != passWordController.text) {
                      //   return "Passwords do not match";
                      // }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),
                  // Register button
                  loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: (){

                        handleRegister();

                    },
                    child: Text(
                      'Register',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Navigation to login
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Input field widget
  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Handle registration logic
  void handleRegister() {
    setState(() {
      loading = true;
    });

    // Simulate a delay for registration process
    Future.delayed(Duration(seconds: 2), () async {


      registrationInProgress = true;
      if (mounted) {
        setState(() {});
      }


      var uuid = Uuid();

      String uniqueId = Unique().generateUniqueID();

      if(selectedRole=="4"){
        uType = 3;
      }else if(selectedRole=="3"){
        uType = 2;
      }else if(selectedRole=="2"){
        uType = 2;
      }else{
        uType = 1;
      }



      if(await InternetConnectionChecker.instance.hasConnection){

      try {

      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(emailController.text.trim());

      if (signInMethods.isNotEmpty) {
      showSnackBarMsg(context, 'Email is already registered.');
      return;
      }

      DatabaseReference usersRef = _databaseRef.child("users");
      DatabaseEvent event = await usersRef.orderByChild("phone").equalTo(phoneController.text.trim()).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
      showSnackBarMsg(context, 'Phone number is already registered.');
      return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      );

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {

      local.User newUser = local.User(
      uniqueid: uniqueId,
      uname: "${nameController.text.trim()}",
      phone: phoneController.text.trim(),
      pass: passwordController.text.trim(),
      email: emailController.text.trim(),
      userid: firebaseUser.uid,
      utype: uType,
      status: 1,
      );

      await _databaseRef.child("users").child(firebaseUser.uid).set(newUser.toMap());

      print("User successfully signed up and saved to database");

      await saveUserOffline(uniqueId, uuid);

      }
      } catch (e) {
      showSnackBarMsg(context,"Signup failed: $e");
      }

      }else{
      showSnackBarMsg(context, "You are in Offline Mode now, Please connect Internet");
      await saveUserOffline(uniqueId, uuid);
      }

    });
  }


  Future<void> saveUserOffline(String uniqueId, Uuid uuid) async {

    // sqlite

    local.User? existingUser = await DatabaseManager().getUserByPhone(phoneController.text.trim());

    if (existingUser != null) {

      if (mounted) {
        showSnackBarMsg(context, 'User already registered');
      }
      registrationInProgress = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    local.User newUser = local.User(
      uniqueid: uniqueId,
      uname: "${nameController.text.trim()}",
      phone: phoneController.text.trim(),
      pass: passwordController.text.trim(),
      email: emailController.text.trim(),
      userid: uuid.v4(),
      utype: uType,
      status: 1,
    );

    int result = await DatabaseManager().insertUser(newUser);


    registrationInProgress = false;
    if (mounted) {
      setState(() {});
    }

    if (result > 0) {
      if (mounted) {
        showSnackBarMsg(context, 'Registration Successful');

        Future.delayed(const Duration(seconds: 0), () {
          setState(() {
            loading = false;
          });

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Login()),
            );
          }
        });

      }
      clearfield();
    } else {
      if (mounted) {
        showSnackBarMsg(context, 'Registration Failed');
      }
    }

  }

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}
