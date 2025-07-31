import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../model/mess/mess_main.dart';
import '../../../model/mess/mess_user.dart';

class ProfileFlipCard extends StatefulWidget {
  final MessUser user;
  final MessMain messInfo;
  final String currentManagerName;
  final String currentManagerPhone;

  const ProfileFlipCard({
    Key? key,
    required this.user,
    required this.messInfo,
    required this.currentManagerName,
    required this.currentManagerPhone,
  }) : super(key: key);

  @override
  _ProfileFlipCardState createState() => _ProfileFlipCardState();
}

class _ProfileFlipCardState extends State<ProfileFlipCard> {
  bool _showUserSide = true;
  final Color _primaryColor = Color(0xFF6C5CE7);
  final Color _secondaryColor = Color(0xFFA29BFE);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showUserSide = !_showUserSide;
        });
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, widget) {
              return Transform(
                transform: Matrix4.rotationY(rotateAnim.value),
                alignment: Alignment.center,
                child: widget,
              );
            },
          );
        },
        child: _showUserSide ? _buildUserSide() : _buildMessSide(),
      ),
    );
  }

  Widget _buildUserSide() {
    return Card(
      key: ValueKey<bool>(true),
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code, size: 30, color: Colors.white),
                  onPressed: () => _showUserQrDialog(),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileItem(
              icon: Icons.person,
              label: 'Name',
              value: widget.user.userId ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.phone,
              label: 'Phone',
              value: widget.user.phone ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.email,
              label: 'Email',
              value: widget.user.email ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.vpn_key,
              label: 'User ID',
              value: widget.user.uniqueId ?? 'N/A',
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.copy,
                  label: 'Copy ID',
                  onPressed: () => _copyToClipboard(widget.user.uniqueId ?? ''),
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: () => _shareUserInfo(),
                ),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap to view Mess info',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessSide() {
    return Card(
      key: ValueKey<bool>(false),
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C6AB), Color(0xFF0082A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(Icons.home, size: 30, color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code, size: 30, color: Colors.white),
                  onPressed: () => _showMessQrDialog(),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileItem(
              icon: Icons.home,
              label: 'Mess Name',
              value: widget.messInfo.messName ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.vpn_key,
              label: 'Mess ID',
              value: widget.messInfo.messId ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.shopping_cart,
              label: 'Current Bazar',
              value: widget.user.userId ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.phone,
              label: 'Bazar Contact',
              value: widget.user.phone ?? 'N/A',
            ),
            _buildProfileItem(
              icon: Icons.manage_accounts,
              label: 'Manager',
              value: widget.currentManagerName,
            ),
            _buildProfileItem(
              icon: Icons.phone,
              label: 'Manager Contact',
              value: widget.currentManagerPhone,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.copy,
                  label: 'Copy Mess ID',
                  onPressed: () => _copyToClipboard(widget.messInfo.messId ?? ''),
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share Mess',
                  onPressed: () => _shareMessInfo(),
                ),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap to view User info',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white.withOpacity(0.8)),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareUserInfo() {
    Share.share(
      'User Information:\n'
          'Name: ${widget.user.userId}\n'
          'Phone: ${widget.user.phone}\n'
          'Email: ${widget.user.email}\n'
          'User ID: ${widget.user.uniqueId}',
    );
  }

  void _shareMessInfo() {
    Share.share(
      'Mess Information:\n'
          'Name: ${widget.messInfo.messName}\n'
          'Address: ${widget.messInfo.messAddress}\n'
          'Mess ID: ${widget.messInfo.messId}\n'
          'Manager: ${widget.currentManagerName} (${widget.currentManagerPhone})',
    );
  }

  void _showUserQrDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User QR Code'),
        content: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replace with your actual QR widget
              Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade200,
                child: Center(
                  child: Text(
                    'QR Code for ${widget.user.uniqueId}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'User ID: ${widget.user.uniqueId}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessQrDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mess QR Code'),
        content: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replace with your actual QR widget
              Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade200,
                child: Center(
                  child: Text(
                    'QR Code for ${widget.messInfo.messId}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Mess ID: ${widget.messInfo.messId}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}