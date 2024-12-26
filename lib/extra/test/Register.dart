import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // Controllers for input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool loading = false; // To show a loading indicator

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
                    'Join Mr BookWorm!',
                    style: TextStyle(fontSize: 16.0, color: Colors.white70),
                  ),
                  SizedBox(height: 32),
                  // Input fields
                  buildInputField(
                    controller: emailController,
                    hint: 'Email',
                    icon: Icons.email,
                    inputType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  buildInputField(
                    controller: nameController,
                    hint: 'Name',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16),
                  buildInputField(
                    controller: cityController,
                    hint: 'City',
                    icon: Icons.location_city,
                  ),
                  SizedBox(height: 16),
                  buildInputField(
                    controller: phoneController,
                    hint: 'Mobile Number',
                    icon: Icons.phone,
                    inputType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  buildInputField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
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
                    onPressed: handleRegister,
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
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        loading = false;
      });

      // Navigate to the Login page after registration
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    });
  }
}
