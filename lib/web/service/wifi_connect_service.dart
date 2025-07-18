// services/wifi_connect_service.dart
import 'package:wifi_iot/wifi_iot.dart';

class WiFiConnectService {
  Future<bool> connectToHotspot(String ssid, String password) async {
    return await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      joinOnce: true,
      security: NetworkSecurity.WPA,
    );
  }
}
