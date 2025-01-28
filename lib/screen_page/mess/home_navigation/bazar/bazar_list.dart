import 'package:flutter/material.dart';

class BazarList extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return BazarListState();
  }

}

class BazarListState extends State<BazarList>{
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
            WeeklySummaryCard(),
            FeaturesGrid(),
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
}

class WeeklySummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Sale', style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: 'Weekly',
                  items: <String>['Weekly', 'Monthly', 'Yearly']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('৳ 9,895', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Expense: ৳ 0'),
                    Text('Weekly Due: ৳ 9,895'),
                    Text('Weekly Profit: ৳ 2,775'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.0),
      children: [
        FeatureIcon(icon: Icons.inventory, label: 'Product'),
        FeatureIcon(icon: Icons.people, label: 'Customers'),
        FeatureIcon(icon: Icons.shopping_cart, label: 'Purchase'),
        FeatureIcon(icon: Icons.receipt, label: 'Sale'),
        FeatureIcon(icon: Icons.list, label: 'Purchase List'),
        FeatureIcon(icon: Icons.list_alt, label: 'Sales List'),
        FeatureIcon(icon: Icons.report, label: 'Reports'),
        FeatureIcon(icon: Icons.trending_down, label: 'Loss/Profit'),
        FeatureIcon(icon: Icons.assignment, label: 'Due List'),
        FeatureIcon(icon: Icons.storage, label: 'Stock List'),
        FeatureIcon(icon: Icons.book, label: 'Ledger'),
        FeatureIcon(icon: Icons.warehouse, label: 'Warehouse'),
        FeatureIcon(icon: Icons.attach_money, label: 'Income'),
        FeatureIcon(icon: Icons.money_off, label: 'Expense'),
        FeatureIcon(icon: Icons.account_balance, label: 'Mortgage'),
        FeatureIcon(icon: Icons.person, label: 'User Role'),
        FeatureIcon(icon: Icons.build, label: 'Manufacture'),
      ],
    );
  }
}

class FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Insaf Enterprise'),
//         actions: [
//           Icon(Icons.chat),
//           SizedBox(width: 8),
//           Icon(Icons.notifications),
//           SizedBox(width: 8),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             TrialPlanBanner(),
//             FinancialMetricsGrid(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
//           BottomNavigationBarItem(icon: Icon(Icons.countertops), label: 'Counter'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }
// }
//
// class TrialPlanBanner extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(16.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text('Your trial plan ends in 364 Days', style: TextStyle(fontSize: 16)),
//             SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () {},
//               child: Text('View Plans'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class FinancialMetricsGrid extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       padding: EdgeInsets.all(16.0),
//       children: [
//         FinancialMetricCard(label: 'Sale', amount: '৳ 9,895', color: Colors.yellow),
//         FinancialMetricCard(label: 'Purchase', amount: '৳ 0', color: Colors.blue),
//         FinancialMetricCard(label: 'Profit', amount: '৳ 2,775', color: Colors.pink),
//         FinancialMetricCard(label: 'Loss', amount: '৳ 0', color: Colors.purple),
//         FinancialMetricCard(label: 'Customer Due', amount: '৳ 19,150', color: Colors.orange),
//         FinancialMetricCard(label: 'Supplier Due', amount: '৳ 0', color: Colors.green),
//         FinancialMetricCard(label: 'Received Due', amount: '৳ 0', color: Colors.teal),
//         FinancialMetricCard(label: 'Total Paid', amount: '৳ 0', color: Colors.red),
//         FinancialMetricCard(label: 'Income', amount: '৳ 0', color: Colors.lightGreen),
//         FinancialMetricCard(label: 'Expense', amount: '৳ 0', color: Colors.lightBlue),
//         FinancialMetricCard(label: 'Sale Return', amount: '0', color: Colors.amber),
//         FinancialMetricCard(label: 'Purchase Return', amount: '0', color: Colors.cyan),
//       ],
//     );
//   }
// }
//
// class FinancialMetricCard extends StatelessWidget {
//   final String label;
//   final String amount;
//   final Color color;
//
//   FinancialMetricCard({required this.label, required this.amount, required this.color});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: color,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
//             SizedBox(height: 8),
//             Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
// }