import 'package:flutter/material.dart';

class MealCounterPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MealCounterPageState();
  }

}

class MealCounterPageState extends State<MealCounterPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("MealCounterPage page")),
    );
  }
}