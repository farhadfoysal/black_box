import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'discovery_screen.dart';
import 'transfers_screen.dart';
import 'settings_screen.dart';

class ServerHomeScreen extends StatefulWidget {
  const ServerHomeScreen({super.key});

  @override
  _ServerHomeScreenState createState() => _ServerHomeScreenState();
}

class _ServerHomeScreenState extends State<ServerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DiscoveryScreen(),
    const ChatScreen(),
    const TransfersScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_copy),
            label: 'Transfers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}