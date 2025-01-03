import 'package:flutter/material.dart';

class BazarList extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return BazarListState();
  }

}

class BazarListState extends State<BazarList>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("BazarList page")),
    );
  }
}