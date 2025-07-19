import 'package:flutter/material.dart';
// import 'package:p2p_communication/p2p_communication.dart';
import 'package:provider/provider.dart';

import '../../cores/models/peer_device.dart';
import '../../cores/network/connection_manager.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  _DiscoveryScreenState createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning
                ? null
                : () async {
              setState(() => _isScanning = true);
              await connectionManager.discoverDevices();
              setState(() => _isScanning = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (connectionManager.isServerRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: const Text('Server is running'),
                backgroundColor: Colors.green[100],
                avatar: const Icon(Icons.check, size: 16),
              ),
            ),
          Expanded(
            child: _buildDeviceList(connectionManager),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServerDialog(context, connectionManager),
        tooltip: 'Start Server',
        child: const Icon(Icons.power_settings_new),
      ),
    );
  }

  Widget _buildDeviceList(ConnectionManager connectionManager) {
    if (connectionManager.isDiscovering) {
      return const Center(child: CircularProgressIndicator());
    }

    if (connectionManager.availableDevices.isEmpty) {
      return const Center(child: Text('No devices found'));
    }

    return ListView.builder(
      itemCount: connectionManager.availableDevices.length,
      itemBuilder: (context, index) {
        final device = connectionManager.availableDevices[index];
        return ListTile(
          leading: const Icon(Icons.devices),
          title: Text(device.name),
          subtitle: Text(device.ipAddress),
          trailing: connectionManager.connectedDevice?.id == device.id
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          onTap: () => _connectToDevice(connectionManager, device),
        );
      },
    );
  }

  Future<void> _connectToDevice(
      ConnectionManager connectionManager,
      PeerDevice device,
      ) async {
    try {
      await connectionManager.connectToDevice(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showServerDialog(
      BuildContext context,
      ConnectionManager connectionManager,
      ) async {
    final deviceNameController = TextEditingController(
      text: 'Device ${connectionManager.localDeviceId?.substring(0, 5)}',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deviceNameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (connectionManager.isServerRunning)
              const Text('Server is already running')
            else
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await connectionManager.startServer(
                      deviceName: deviceNameController.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Server started')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Start Server'),
              ),
          ],
        ),
        actions: [
          if (connectionManager.isServerRunning)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await connectionManager.stopServer();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server stopped')),
                  );
                }
              },
              child: const Text('Stop Server'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../cores/network/connection_manager.dart';
// import 'chat_screen.dart';
//
// class DiscoveryScreen extends StatefulWidget {
//   const DiscoveryScreen({super.key});
//
//   @override
//   State<DiscoveryScreen> createState() => _DiscoveryScreenState();
// }
//
// class _DiscoveryScreenState extends State<DiscoveryScreen> {
//   bool _isDiscovering = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initServer();
//   }
//
//   Future<void> _initServer() async {
//     await Provider.of<ConnectionManager>(context, listen: false).startServer();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final connectionManager = Provider.of<ConnectionManager>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Available Devices'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _isDiscovering
//                 ? null
//                 : () async {
//               setState(() => _isDiscovering = true);
//               await connectionManager.discoverDevices();
//               if (mounted) {
//                 setState(() => _isDiscovering = false);
//               }
//             },
//           ),
//         ],
//       ),
//       body: _isDiscovering
//           ? const Center(child: CircularProgressIndicator())
//           : connectionManager.availableDevices.isEmpty
//           ? const Center(
//           child: Text('No devices found. Make sure other devices are running the app on the same network.'))
//           : ListView.builder(
//         itemCount: connectionManager.availableDevices.length,
//         itemBuilder: (context, index) {
//           final device = connectionManager.availableDevices[index];
//           return ListTile(
//             leading: const Icon(Icons.devices),
//             title: Text(device.name),
//             subtitle: Text(device.ipAddress),
//             trailing: const Icon(Icons.signal_wifi_4_bar),
//             onTap: () async {
//               final success = await connectionManager.connectToDevice(device);
//               if (success && mounted) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ChatScreen(peerDevice: device),
//                   ),
//                 );
//               }
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           setState(() => _isDiscovering = true);
//           await connectionManager.discoverDevices();
//           if (mounted) {
//             setState(() => _isDiscovering = false);
//           }
//         },
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }
// }