import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return PaymentPageState();
  }

}

class PaymentPageState extends State<PaymentPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("PaymentPage page")),
    );
  }
}