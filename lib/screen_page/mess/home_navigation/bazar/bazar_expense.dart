import 'package:flutter/material.dart';

class BazarExpense extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return BazarExpenseState();
  }

}

class BazarExpenseState extends State<BazarExpense>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("BazarExpense page")),
    );
  }
}