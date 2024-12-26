import 'package:black_box/screen_page/signin/login.dart';
import 'package:flutter/material.dart';

import '../model/school/school.dart';

class ExternalUtility{

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Custom Dropdown displayed when item is selected
  Widget _customDropDown(BuildContext context, School? item) {
    if (item == null) {
      return Text("No School Selected", style: TextStyle(color: Colors.grey));
    }
    return ListTile(
      leading: Icon(Icons.school, color: Colors.blue),
      title: Text(item.sName!, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("sId: ${item.sId}"),
    );
  }

  // Custom Popup item in the dropdown list
  Widget _customPopupItemBuilder(BuildContext context, School item, bool isSelected) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
        borderRadius: BorderRadius.circular(5),
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(Icons.school),
        title: Text(item.sName!),
        subtitle: Text("sId: ${item.sId}"),
      ),
    );
  }
}