import 'package:flutter/material.dart';
// import 'package:p2p_communication/p2p_communication.dart';
import 'package:provider/provider.dart';

import '../../cores/network/connection_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDeviceInfoCard(connectionManager),
          const SizedBox(height: 16),
          _buildConnectionSettings(connectionManager),
          const SizedBox(height: 16),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard(ConnectionManager connectionManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.device_unknown),
              title: const Text('Device ID'),
              subtitle: Text(connectionManager.localDeviceId ?? 'Unknown'),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Storage Path'),
              subtitle: Text('/storage/emulated/0/P2PFiles'), // Example path
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSettings(ConnectionManager connectionManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable Auto Discovery'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Accept Incoming Files'),
              value: true,
              onChanged: (value) {},
            ),
            ListTile(
              title: const Text('Server Port'),
              trailing: Text('${connectionManager.isServerRunning ? 8080 : 'Not running'}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            ListTile(
              title: Text('Version'),
              subtitle: Text('1.0.0'),
            ),
            ListTile(
              title: Text('Developer'),
              subtitle: Text('Your Company'),
            ),
            ListTile(
              title: Text('Privacy Policy'),
              onTap: null, // Add navigation to privacy policy
            ),
          ],
        ),
      ),
    );
  }
}