import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    if (await Permission.locationWhenInUse.isGranted) {
      return true;
    }
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<bool> requestHotspotPermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) {
      return true;
    }
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    return await requestStoragePermission() &&
        await requestLocationPermission() &&
        await requestHotspotPermission() &&
        await requestCameraPermission();
  }
}