import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class WifiHotspotManager {
  static const MethodChannel _channel = MethodChannel('com.yourcompany/hotspot');

  Future<bool> enableHotspot({required String ssid, required String password}) async {
    try {
      return await _channel.invokeMethod('enableHotspot', {
        'ssid': ssid,
        'password': password,
      });
    } on PlatformException catch (e) {
      debugPrint('Hotspot enable error: ${e.message}');
      return false;
    }
  }

  Future<bool> disableHotspot() async {
    try {
      return await _channel.invokeMethod('disableHotspot');
    } on PlatformException catch (e) {
      debugPrint('Hotspot disable error: ${e.message}');
      return false;
    }
  }

  Future<String?> getHotspotIp() async {
    try {
      return await _channel.invokeMethod('getHotspotIp');
    } on PlatformException catch (e) {
      debugPrint('Get hotspot IP error: ${e.message}');
      return null;
    }
  }

  Future<List<String>> getConnectedDevices() async {
    try {
      final devices = await _channel.invokeMethod('getConnectedDevices');
      return List<String>.from(devices);
    } on PlatformException catch (e) {
      debugPrint('Get connected devices error: ${e.message}');
      return [];
    }
  }
}