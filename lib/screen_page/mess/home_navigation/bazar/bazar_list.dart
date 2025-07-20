import 'package:flutter/material.dart';

class BazarList extends StatefulWidget {
  @override
  State<BazarList> createState() => BazarListState();
}

class BazarListState extends State<BazarList> {
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insaf Enterprise'),
        actions: [
          Icon(Icons.chat),
          SizedBox(width: 8),
          Icon(Icons.notifications),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TrialPlanBanner(),
            FinancialMetricsGrid(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.countertops), label: 'Counter'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }


  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(
  //         'Insaf Enterprise',
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       backgroundColor: Colors.teal.shade700,
  //       elevation: 0,
  //       actions: [
  //         IconButton(
  //           icon: Icon(Icons.chat, color: Colors.white),
  //           onPressed: () {},
  //         ),
  //         Stack(
  //           children: [
  //             IconButton(
  //               icon: Icon(Icons.notifications, color: Colors.white),
  //               onPressed: () {},
  //             ),
  //             Positioned(
  //               right: 8,
  //               top: 8,
  //               child: Container(
  //                 padding: EdgeInsets.all(2),
  //                 decoration: BoxDecoration(
  //                   color: Colors.red,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 constraints: BoxConstraints(
  //                   minWidth: 16,
  //                   minHeight: 16,
  //                 ),
  //                 child: Text(
  //                   '',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 10,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //     body: SingleChildScrollView(
  //       child: Column(
  //         children: [
  //           WeeklySummaryCard(),
  //           FeaturesGrid(),
  //         ],
  //       ),
  //     ),
  //     bottomNavigationBar: Container(
  //       decoration: BoxDecoration(
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.withOpacity(0.3),
  //             spreadRadius: 1,
  //             blurRadius: 5,
  //             offset: Offset(0, -2),
  //           ),
  //         ],
  //       ),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //         child: BottomNavigationBar(
  //           type: BottomNavigationBarType.fixed,
  //           backgroundColor: Colors.white,
  //           selectedItemColor: Colors.teal.shade700,
  //           unselectedItemColor: Colors.grey.shade600,
  //           selectedLabelStyle: TextStyle(fontSize: 12),
  //           items: [
  //             BottomNavigationBarItem(
  //               icon: Icon(Icons.home_outlined),
  //               activeIcon: Icon(Icons.home),
  //               label: 'Home',
  //             ),
  //             BottomNavigationBarItem(
  //               icon: Icon(Icons.dashboard_outlined),
  //               activeIcon: Icon(Icons.dashboard),
  //               label: 'Dashboard',
  //             ),
  //             BottomNavigationBarItem(
  //               icon: Icon(Icons.countertops_outlined),
  //               activeIcon: Icon(Icons.countertops),
  //               label: 'Counter',
  //             ),
  //             BottomNavigationBarItem(
  //               icon: Icon(Icons.settings_outlined),
  //               activeIcon: Icon(Icons.settings),
  //               label: 'Settings',
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class WeeklySummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade800,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: DropdownButton<String>(
                    value: 'Weekly',
                    icon: Icon(Icons.arrow_drop_down, size: 20),
                    iconSize: 16,
                    elevation: 0,
                    underline: SizedBox(),
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontSize: 14,
                    ),
                    items: <String>['Weekly', 'Monthly', 'Yearly']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '৳ 9,895',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    Text(
                      'Total Sales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSummaryItem('Expense', '৳ 0', Colors.orange.shade600),
                    _buildSummaryItem('Due', '৳ 9,895', Colors.red.shade600),
                    _buildSummaryItem('Profit', '৳ 2,775', Colors.green.shade600),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> features = [
    {'icon': Icons.inventory, 'label': 'Product', 'color': Colors.blue.shade600},
    {'icon': Icons.people, 'label': 'Customers', 'color': Colors.green.shade600},
    {'icon': Icons.shopping_cart, 'label': 'Purchase', 'color': Colors.orange.shade600},
    {'icon': Icons.receipt, 'label': 'Sale', 'color': Colors.purple.shade600},
    {'icon': Icons.list, 'label': 'Purchase List', 'color': Colors.blue.shade400},
    {'icon': Icons.list_alt, 'label': 'Sales List', 'color': Colors.green.shade400},
    {'icon': Icons.report, 'label': 'Reports', 'color': Colors.red.shade600},
    {'icon': Icons.trending_down, 'label': 'Loss/Profit', 'color': Colors.amber.shade600},
    {'icon': Icons.assignment, 'label': 'Due List', 'color': Colors.indigo.shade600},
    {'icon': Icons.storage, 'label': 'Stock List', 'color': Colors.blueGrey.shade600},
    {'icon': Icons.book, 'label': 'Ledger', 'color': Colors.brown.shade600},
    {'icon': Icons.warehouse, 'label': 'Warehouse', 'color': Colors.deepOrange.shade600},
    {'icon': Icons.attach_money, 'label': 'Income', 'color': Colors.lightGreen.shade600},
    {'icon': Icons.money_off, 'label': 'Expense', 'color': Colors.pink.shade600},
    {'icon': Icons.account_balance, 'label': 'Mortgage', 'color': Colors.teal.shade600},
    {'icon': Icons.person, 'label': 'User Role', 'color': Colors.cyan.shade600},
    {'icon': Icons.build, 'label': 'Manufacture', 'color': Colors.deepPurple.shade600},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: features.map((feature) {
        return FeatureIcon(
          icon: feature['icon'],
          label: feature['label'],
          color: feature['color'],
        );
      }).toList(),
    );
  }
}

class FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const FeatureIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}




class TrialPlanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Premium Trial',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Your trial plan ends in 364 Days',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                onPressed: () {},
                child: Text(
                  'View Plans',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialMetricsGrid extends StatelessWidget {
  final List<FinancialMetric> metrics = [
    FinancialMetric(label: 'Sale', amount: '৳ 9,895', color: Colors.amber.shade600),
    FinancialMetric(label: 'Purchase', amount: '৳ 0', color: Colors.blue.shade600),
    FinancialMetric(label: 'Profit', amount: '৳ 2,775', color: Colors.green.shade600),
    FinancialMetric(label: 'Loss', amount: '৳ 0', color: Colors.red.shade600),
    FinancialMetric(label: 'Customer Due', amount: '৳ 19,150', color: Colors.orange.shade600),
    FinancialMetric(label: 'Supplier Due', amount: '৳ 0', color: Colors.teal.shade600),
    FinancialMetric(label: 'Received Due', amount: '৳ 0', color: Colors.lightGreen.shade600),
    FinancialMetric(label: 'Total Paid', amount: '৳ 0', color: Colors.purple.shade600),
    FinancialMetric(label: 'Income', amount: '৳ 0', color: Colors.lightBlue.shade600),
    FinancialMetric(label: 'Expense', amount: '৳ 0', color: Colors.pink.shade600),
    FinancialMetric(label: 'Sale Return', amount: '0', color: Colors.cyan.shade600),
    FinancialMetric(label: 'Purchase Return', amount: '0', color: Colors.deepOrange.shade600),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: metrics.map((metric) {
        return FinancialMetricCard(
          label: metric.label,
          amount: metric.amount,
          color: metric.color,
        );
      }).toList(),
    );
  }
}

class FinancialMetricCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const FinancialMetricCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.8), color],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 8),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialMetric {
  final String label;
  final String amount;
  final Color color;

  FinancialMetric({
    required this.label,
    required this.amount,
    required this.color,
  });
}