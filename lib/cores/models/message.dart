import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum MessageStatus { sending, sent, delivered, failed }

class Message {
  final String id;
  final String text;
  final String senderId;
  final String? receiverId;
  final DateTime timestamp;
  late final bool isSent;
  MessageStatus status;
  final String? filePath;
  final String? fileName;
  final int? fileSize;

  Message({
    String? id,
    required this.text,
    required this.senderId,
    this.receiverId,
    DateTime? timestamp,
    this.isSent = false,
    this.status = MessageStatus.sending,
    this.filePath,
    this.fileName,
    this.fileSize,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      timestamp: DateTime.parse(json['timestamp']),
      isSent: json['isSent'],
      status: MessageStatus.values[json['status']],
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'isSent': isSent,
      'status': status.index,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  Message copyWith({
    String? text,
    MessageStatus? status,
    String? filePath,
    String? fileName,
    int? fileSize,
  }) {
    return Message(
      id: id,
      text: text ?? this.text,
      senderId: senderId,
      receiverId: receiverId,
      timestamp: timestamp,
      isSent: isSent,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}