import 'package:flutter/material.dart';

class MessHomeMember extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MessHomeMemberState();
  }
}

class MessHomeMemberState extends State<MessHomeMember> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mess Home Member"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigates back to the previous page
          },
        ),
      ),
      body: Center(
        child: Text("Messhome Member"),
      ),
    );
  }
}
