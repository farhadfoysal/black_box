import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:p2p_communication/p2p_communication.dart';
import 'package:provider/provider.dart';

import '../../cores/models/message.dart';
import '../../cores/network/connection_manager.dart';
import '../../cores/utils/network_utils.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Add this to your chat screen's initState
  @override
  void initState() {
    super.initState();
    // _testMessageFlow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
      final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
      connectionManager.debugPrintConnections();
      connectionManager.debugPrintMessages();
    });
  }

  Future<void> _checkConnection() async {
    final connectionManager = context.read<ConnectionManager>();
    if (connectionManager.connectedDevice == null) return;

    final isReachable = await NetworkUtils.canConnectToDevice(
      connectionManager.connectedDevice!.ipAddress,
      ConnectionManager.serverPort,
    );

    if (!isReachable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost, attempting to reconnect')),
      );
      connectionManager.disconnect();
    }
  }

// Test message flow
  void _testMessageFlow() async {
    final connectionManager = Provider.of<ConnectionManager>(context, listen: false);

    // Test local message
    await connectionManager.sendMessage('Local test message', isSystemMessage: true);

    // Test network message if connected
    if (connectionManager.connectedDevice != null) {
      await connectionManager.sendMessage('Network test message');
    }

    connectionManager.debugPrintMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context);

    // Debugging - print when messages change
    debugPrint('Messages updated: ${connectionManager.messages.length}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
            connectionManager.connectedDevice?.name ?? 'No device connected'),
        actions: [
          if (connectionManager.connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _disconnect(connectionManager),
            ),
        ],
      ),
      // body: Column(
      //   children: [
      //     Expanded(
      //       child: _buildMessageList(connectionManager),
      //     ),
      //     _buildMessageInput(connectionManager),
      //   ],
      // ),

      body: Consumer<ConnectionManager>(
        builder: (context, manager, child) {
          return Column(
            children: [
              // GestureDetector(
              //   onLongPress: _testMessageFlow,
              //   child: Container(color: Colors.transparent),
              // ),
              // Expanded(
              //   child: _buildMessageList(connectionManager),
              // ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: manager.messages.length,
                  itemBuilder: (context, index) {
                    final message = manager.messages[index];
                    debugPrint('Displaying message: ${message.text}');
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              _buildMessageInput(manager),
            ],
          );
        },
      ),

    );
  }

  Widget _buildMessageList(ConnectionManager connectionManager) {
    if (connectionManager.messages.isEmpty) {
      return const Center(child: Text('No messages yet'));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: connectionManager.messages.length,
      itemBuilder: (context, index) {
        final message = connectionManager.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isSent = message.isSent;
    final hasFile = message.fileName != null;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSent ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
          isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (hasFile) ...[
              const Icon(Icons.insert_drive_file, size: 40),
              const SizedBox(height: 4),
              Text(
                message.fileName!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (message.fileSize != null)
                Text(
                  '${(message.fileSize! / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 8),
            ],
            Text(message.text),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ConnectionManager connectionManager) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _sendFile(connectionManager),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) => _sendMessage(connectionManager),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(connectionManager),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(ConnectionManager connectionManager) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (connectionManager.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device connected')),
      );
      return;
    }

    try {
      await connectionManager.sendMessage(text);
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendFile(ConnectionManager connectionManager) async {
    if (connectionManager.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device connected')),
      );
      return;
    }

    // In a real app, use file_picker package to select files
    // For demo purposes, we'll simulate a file selection
    final file = File('/path/to/sample/file.txt');
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    try {
      await connectionManager.sendFile(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send file: ${e.toString()}')),
      );
    }
  }

  Future<void> _disconnect(ConnectionManager connectionManager) async {
    await connectionManager.disconnect();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected')),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../cores/models/peer_device.dart';
// import '../../cores/network/connection_manager.dart';
// import '../widgets/message_bubble.dart';
//
// class ChatScreen extends StatefulWidget {
//   final PeerDevice peerDevice;
//
//   const ChatScreen({super.key, required this.peerDevice});
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     final connectionManager = Provider.of<ConnectionManager>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.peerDevice.name),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: true,
//               itemCount: connectionManager.messages.length,
//               itemBuilder: (context, index) {
//                 final message = connectionManager.messages.reversed.toList()[index];
//                 return MessageBubble(
//                   message: message,
//                   isMe: message.isSent,
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: const InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: () {
//                     if (_messageController.text.trim().isNotEmpty) {
//                       connectionManager.sendMessage(_messageController.text.trim());
//                       _messageController.clear();
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }