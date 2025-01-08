import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../db/local/database_manager.dart';
import '../../model/mess/mess_user.dart';

class MessController extends GetxController {
  var currentUser = MessUser().obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  final _databaseRef = FirebaseDatabase.instance.ref();

  Future<bool> joinMess(String messCode) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Update the MessUser locally
      currentUser.update((user) {
        user?.messId = messCode;
      });

      await saveLocally(currentUser.value);

      bool success = await saveRemotely(currentUser.value);

      if (success) {
        Get.snackbar('Success', 'Joined mess successfully!');
      } else {
        errorMessage.value = 'Failed to join the mess.';
      }

      return success;
    } catch (e) {
      errorMessage.value = 'An error occurred while joining the mess: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveLocally(MessUser user) async {

    MessUser? existingUser = await DatabaseManager().getMessUserByPhone(user.phone!);

    if (existingUser != null) {

      return;
    }
    int result = await DatabaseManager().insertMessUser(user);
    if (result > 0) {

    } else {
      return;
    }
    print("User saved locally: ${user.toMap()}");
  }


  Future<bool> saveRemotely(MessUser user) async {

    try {
      DatabaseReference usersRef = _databaseRef.child("musers");
      DatabaseEvent event = await usersRef.orderByChild("phone").equalTo(user.phone).once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        return false;
      }

      await _databaseRef.child("musers").child(user.uniqueId!).set(user.toMap());

      print("User saved remotely: ${user.toMap()}");
      return true;
    } catch (e) {
      print("User Phone number exist or  Failed to save user remotely: $e");
      return false;
    }
  }
}
