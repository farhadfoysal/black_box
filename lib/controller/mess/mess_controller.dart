import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../model/mess/mess_user.dart';

class MessController extends GetxController {
  var currentUser = MessUser().obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Method to join mess locally and remotely
  Future<bool> joinMess(String messCode) async {
    try {
      isLoading.value = true;
      errorMessage.value = ''; // Clear any previous error

      // Update the MessUser locally
      currentUser.update((user) {
        user?.messId = messCode;
      });

      // Save locally (e.g., SharedPreferences or local database)
      await saveLocally(currentUser.value);

      // Save remotely (e.g., Firebase or API call)
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

  // Save MessUser locally (e.g., using SharedPreferences or Hive)
  Future<void> saveLocally(MessUser user) async {
    // Implement local save logic here, for example:
    print("User saved locally: ${user.toMap()}");
  }

  // Save MessUser remotely (e.g., Firebase or REST API)
  Future<bool> saveRemotely(MessUser user) async {
    try {
      // Implement remote save logic here
      print("User saved remotely: ${user.toMap()}");
      return true;
    } catch (e) {
      print("Failed to save user remotely: $e");
      return false;
    }
  }
}
