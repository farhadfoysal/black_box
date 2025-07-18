import 'package:wifi_iot/wifi_iot.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class HotspotManager {
  static Future<bool> createHotspot({
    required String ssid,
    required String password,
  }) async {
    try {
      // Check if we're on Android and get API level
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt ?? 0;

        // For API level >= 26, we can't set SSID/password programmatically
        if (sdkInt >= 26) {
          // Just try to enable hotspot with existing settings
          return await _enableHotspotOnly();
        }
      }

      // For older Android versions or non-Android platforms
      return await _createHotspotWithConfig(ssid, password);
    } catch (e) {
      print("Hotspot creation error: $e");
      return false;
    }
  }

  static Future<bool> _createHotspotWithConfig(String ssid, String password) async {
    try {
      // Disable hotspot first if enabled
      if (await WiFiForIoTPlugin.isWiFiAPEnabled()) {
        await WiFiForIoTPlugin.setWiFiAPEnabled(false);
        await Future.delayed(const Duration(seconds: 2));
      }

      // Set hotspot configuration
      await WiFiForIoTPlugin.setWiFiAPSSID(ssid);
      await WiFiForIoTPlugin.setWiFiAPPreSharedKey(password);

      // Enable hotspot
      return await WiFiForIoTPlugin.setWiFiAPEnabled(true);
    } catch (e) {
      print("Error creating hotspot with config: $e");
      return false;
    }
  }

  static Future<bool> _enableHotspotOnly() async {
    try {
      // Just toggle the hotspot state without changing config
      final isEnabled = await WiFiForIoTPlugin.isWiFiAPEnabled();
      return await WiFiForIoTPlugin.setWiFiAPEnabled(!isEnabled);
    } catch (e) {
      print("Error enabling hotspot: $e");
      return false;
    }
  }

  static Future<bool> enableHotspot() async {
    try {
      return await WiFiForIoTPlugin.setWiFiAPEnabled(true);
    } catch (e) {
      print("Error enabling hotspot: $e");
      return false;
    }
  }

  static Future<bool> stopHotspot() async {
    return await WiFiForIoTPlugin.setWiFiAPEnabled(false);
  }

  static Future<String?> getHotspotIP() async {
    try {
      // Common hotspot IP ranges
      const possibleHotspotIps = [
        '192.168.43.1', // Most common Android hotspot IP
        '192.168.44.1', // Some Samsung devices
        '192.168.42.1', // Some Huawei devices
        '192.168.1.1'   // Some other devices
      ];

      // Try to get actual IP
      final info = NetworkInfo();
      final ip = await info.getWifiIP();

      // Check if the IP is in hotspot range
      if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
        for (var hotspotIp in possibleHotspotIps) {
          if (ip == hotspotIp ||
              ip.startsWith(hotspotIp.substring(0, hotspotIp.lastIndexOf('.')))) {
            return ip;
          }
        }
      }

      // Fallback to checking common hotspot IPs
      for (var hotspotIp in possibleHotspotIps) {
        try {
          final socket = await Socket.connect(hotspotIp, 80, timeout: Duration(seconds: 1));
          await socket.close();
          return hotspotIp;
        } catch (_) {}
      }

      // Final fallback
      return possibleHotspotIps.first;
    } catch (e) {
      print("Error getting hotspot IP: $e");
      return '192.168.43.1';
    }
  }

  static Future<bool> isHotspotEnabled() async {
    return await WiFiForIoTPlugin.isWiFiAPEnabled();
  }
}