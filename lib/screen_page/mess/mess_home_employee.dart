import 'package:flutter/material.dart';

class MessHomeEmployee extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MessHomeEmployeeState();
  }
}

class MessHomeEmployeeState extends State<MessHomeEmployee> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mess Home Employee"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigates back to the previous page
          },
        ),
      ),
      body: Center(
        child: Text("Messhome Employee"),
      ),
    );
  }
}
