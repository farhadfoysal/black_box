import 'package:uuid/uuid.dart';

enum TransferStatusType { queued, inProgress, paused, completed, failed }

class TransferStatus {
  final String id;
  final String fileName;
  final int fileSize;
  final int progress;
  final TransferStatusType status;
  final bool isIncoming;
  final DateTime startTime;
  final DateTime? endTime;

  TransferStatus({
    String? id,
    required this.fileName,
    required this.fileSize,
    this.progress = 0,
    this.status = TransferStatusType.queued,
    this.isIncoming = false,
    DateTime? startTime,
    this.endTime,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  TransferStatus copyWith({
    int? progress,
    TransferStatusType? status,
    DateTime? endTime,
  }) {
    return TransferStatus(
      id: id,
      fileName: fileName,
      fileSize: fileSize,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      isIncoming: isIncoming,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}