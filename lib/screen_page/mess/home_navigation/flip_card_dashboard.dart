import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class FlipCardDashboard extends StatefulWidget {
  @override
  _FlipCardDashboardState createState() => _FlipCardDashboardState();
}

class _FlipCardDashboardState extends State<FlipCardDashboard> {
  bool _isFrontSide = true;
  final List<DashboardItem> _dashboardItems = [
    DashboardItem(
      title: 'আমার ওয়ালেট',
      icon: Icons.account_balance_wallet,
      color: Colors.purple.shade400,
      subtitle: 'ব্যক্তিগত ব্যালেন্স',
    ),
    DashboardItem(
      title: 'মিলের তালিকা',
      icon: Icons.list_alt,
      color: Colors.blue.shade400,
      subtitle: 'দৈনিক মিল রেকর্ড',
    ),
    DashboardItem(
      title: 'বাজারের তারিখ',
      icon: Icons.shopping_cart,
      color: Colors.green.shade400,
      subtitle: 'বাজার রুটিন',
    ),
    DashboardItem(
      title: 'সমস্ত খরচ',
      icon: Icons.monetization_on,
      color: Colors.orange.shade400,
      subtitle: 'মাসিক ব্যয়',
    ),
    DashboardItem(
      title: 'মেস ওয়ালেট',
      icon: Icons.wallet_membership,
      color: Colors.teal.shade400,
      subtitle: 'সামগ্রিক ব্যালেন্স',
    ),
    DashboardItem(
      title: 'ডকুমেন্টস',
      icon: Icons.picture_as_pdf,
      color: Colors.red.shade400,
      subtitle: 'ফাইল ও রিপোর্ট',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFrontSide = !_isFrontSide;
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
        child: _isFrontSide ? _buildFrontSide() : _buildBackSide(),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Card(
      key: ValueKey<bool>(true),
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'অপারেশন',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildOperationTile(
                  icon: Icons.account_balance_wallet,
                  label: 'আমার ওয়ালেট',
                  color: Colors.purple.shade400,
                ),
                _buildOperationTile(
                  icon: Icons.list_alt,
                  label: 'মিলের তালিকা',
                  color: Colors.blue.shade400,
                ),
                _buildOperationTile(
                  icon: Icons.shopping_cart,
                  label: 'বাজারের তারিখ',
                  color: Colors.green.shade400,
                ),
                _buildOperationTile(
                  icon: Icons.monetization_on,
                  label: 'সমস্ত খরচ',
                  color: Colors.orange.shade400,
                ),
                _buildOperationTile(
                  icon: Icons.wallet_membership,
                  label: 'মেস ওয়ালেট',
                  color: Colors.teal.shade400,
                ),
                _buildOperationTile(
                  icon: Icons.picture_as_pdf,
                  label: 'ডকুমেন্টস',
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Card(
      key: ValueKey<bool>(false),
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Operation Menu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 210,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: _dashboardItems.length,
                itemBuilder: (context, index) {
                  return Transform.translate(
                    offset: index.isEven
                        ? const Offset(0, 20)
                        : Offset.zero,
                    child: _buildHexItem(_dashboardItems[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationTile({required IconData icon, required String label, required Color color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHexItem(DashboardItem item) {
    return GestureDetector(
      onTap: () {
        // Handle item tap
      },
      child: Column(
        children: [
          ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              width: 60,
              height: 60,
              color: item.color.withOpacity(0.2),
              child: Center(
                child: Icon(item.icon, color: item.color),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;

  DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}