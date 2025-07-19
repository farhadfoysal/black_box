import 'package:flutter/foundation.dart';

class PeerDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int signalStrength;
  final String? deviceModel;
  final DateTime lastSeen;

  PeerDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.signalStrength = 0,
    this.deviceModel,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory PeerDevice.fromJson(Map<String, dynamic> json) {
    return PeerDevice(
      id: json['id'],
      name: json['name'],
      ipAddress: json['ipAddress'],
      signalStrength: json['signalStrength'] ?? 0,
      deviceModel: json['deviceModel'],
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'signalStrength': signalStrength,
      'deviceModel': deviceModel,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}