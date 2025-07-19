import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/peer_device.dart';
import '../exceptions/p2p_exceptions.dart';

class NetworkUtils {
  static Future<String?> getLocalIp() async {
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      throw P2PNetworkException('Failed to get local IP: ${e.toString()}');
    }
    return null;
  }

  static Future<List<PeerDevice>> scanLocalNetwork({
    int port = 8080,
    int timeout = 2000,
    int maxParallelScans = 20,
  }) async {
    try {
      final localIp = await getLocalIp();
      if (localIp == null) return [];

      final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
      final client = http.Client();
      final devices = <PeerDevice>[];
      final futures = <Future>[];

      // Scan IPs 1-254 in batches
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (ip == localIp) continue;

        futures.add(_checkDevice(client, ip, port, timeout).then((device) {
          if (device != null) devices.add(device);
        }));

        // Limit parallel requests
        if (futures.length >= maxParallelScans) {
          await Future.wait(futures);
          futures.clear();
        }
      }

      // Wait for remaining requests
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      client.close();
      return devices;
    } catch (e) {
      throw P2PNetworkException('Network scan failed: ${e.toString()}');
    }
  }

  static Future<PeerDevice?> _checkDevice(
      http.Client client,
      String ip,
      int port,
      int timeout,
      ) async {
    try {
      final response = await client.get(
        Uri.parse('http://$ip:$port/status'),
        headers: {'Connection': 'close'},
      ).timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PeerDevice(
          id: data['deviceId'] ?? ip,
          name: data['deviceName'] ?? 'Device $ip',
          ipAddress: ip,
        );
      }
    } catch (_) {
      // Timeout or connection error - skip
    }
    return null;
  }

  static Future<void> ensureNetworkPermissions() async {
    // Placeholder for platform-specific permission checks
    // In a real app, this would check and request necessary permissions
  }
}