import 'package:flutter/material.dart';

class PersonalDetailsPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
   return PersonalDetailsPageState();
  }

}

class PersonalDetailsPageState extends State<PersonalDetailsPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Personal page")),
    );
  }
}