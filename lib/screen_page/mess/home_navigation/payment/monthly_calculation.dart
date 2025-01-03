import 'package:flutter/material.dart';

class MonthlyCalculation extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MonthlyCalculationState();
  }

}

class MonthlyCalculationState extends State<MonthlyCalculation>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("MonthlyCalculation page")),
    );
  }
}