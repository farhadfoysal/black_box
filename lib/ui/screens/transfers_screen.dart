import 'package:flutter/material.dart';
// import 'package:p2p_communication/p2p_communication.dart';
import 'package:provider/provider.dart';

import '../../cores/models/transfer_status.dart';
import '../../cores/network/connection_manager.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfers'),
      ),
      body: _buildTransfersList(connectionManager),
    );
  }

  Widget _buildTransfersList(ConnectionManager connectionManager) {
    if (connectionManager.activeTransfers.isEmpty) {
      return const Center(child: Text('No active transfers'));
    }

    return ListView.builder(
      itemCount: connectionManager.activeTransfers.length,
      itemBuilder: (context, index) {
        final transfer = connectionManager.activeTransfers[index];
        return _buildTransferTile(transfer);
      },
    );
  }

  Widget _buildTransferTile(TransferStatus transfer) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(transfer.fileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: transfer.progress / 100,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 4),
          Text(
            '${transfer.progress}% • ${_formatFileSize(transfer.fileSize)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: _getTransferStatusIcon(transfer.status),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget? _getTransferStatusIcon(TransferStatusType status) {
    switch (status) {
      case TransferStatusType.queued:
        return const Icon(Icons.access_time, color: Colors.blue);
      case TransferStatusType.inProgress:
        return const CircularProgressIndicator();
      case TransferStatusType.paused:
        return const Icon(Icons.pause, color: Colors.orange);
      case TransferStatusType.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TransferStatusType.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }
}