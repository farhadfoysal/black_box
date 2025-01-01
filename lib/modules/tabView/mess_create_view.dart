import 'package:flutter/material.dart';

import '../../cores/cores.dart';

class MessCreateView extends StatefulWidget {
  @override
  State<MessCreateView> createState() => _MessCreateViewState();
}

class _MessCreateViewState extends State<MessCreateView> {
  bool isJoining = false; // Toggle between create and join forms

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isJoining ? "Join Mess" : "Create New Mess",
              style: p21.bold,
            ),
            SizedBox(height: 20),
            if (!isJoining) ...[
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Mess Name",
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Phone",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Create Mess
                },
                child: Text("Create Mess"),
              ),
            ] else ...[
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Mess Code",
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Join Mess
                },
                child: Text("Join Mess"),
              ),
            ],
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  isJoining = !isJoining; // Toggle between forms
                });
              },
              child: Text(
                isJoining ? "Create a New Mess Instead" : "Already have a Mess? Join with Code",
                style: TextStyle(color: context.theme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}