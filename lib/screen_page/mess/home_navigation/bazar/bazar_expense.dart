import 'package:flutter/material.dart';

class BazarExpense extends StatefulWidget {
  @override
  State<BazarExpense> createState() => BazarExpenseState();
}

class BazarExpenseState extends State<BazarExpense> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Balance List',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.print, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Icon(Icons.person, color: Colors.teal.shade700),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(5, (index) {
            return BalanceCard(
              name: 'User ${index + 1}',
              meals: 6,
              rate: 0,
              total: 748.00,
              paid: '0B/0P',
              balance: 748.00,
              phone: '01872317375',
            );
          }),
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final String name;
  final int meals;
  final int rate;
  final double total;
  final String paid;
  final double balance;
  final String phone;

  const BalanceCard({
    required this.name,
    required this.meals,
    required this.rate,
    required this.total,
    required this.paid,
    required this.balance,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    phone,
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Meal and Rate Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Meals', '$meals', Colors.blue.shade600),
                _buildInfoItem('Rate', '$rate', Colors.orange.shade600),
                _buildInfoItem('Total', '$total', Colors.green.shade600),
              ],
            ),
            SizedBox(height: 16),

            // Payment Status
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPaymentItem('Paid', paid, Colors.grey.shade600),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildPaymentItem('Balance', '$balance', Colors.red.shade600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}


// import 'package:flutter/material.dart';
//
// class BazarExpense extends StatefulWidget{
//   @override
//   State<StatefulWidget> createState() {
//     return BazarExpenseState();
//   }
//
// }
//
// class BazarExpenseState extends State<BazarExpense>{
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Balance List'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.print),
//             onPressed: () {},
//           ),
//           CircleAvatar(
//             backgroundImage: AssetImage('assets/avatar.png'),
//           ),
//           SizedBox(width: 8),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: List.generate(5, (index) {
//             return BalanceCard(
//               name: 'User ${index + 1}',
//               meals: 6,
//               rate: 0,
//               total: 748.00,
//               paid: '0B/0P',
//               balance: 748.00,
//               phone: '01872317375',
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }
//
// class BalanceCard extends StatelessWidget {
//   final String name;
//   final int meals;
//   final int rate;
//   final double total;
//   final String paid;
//   final double balance;
//   final String phone;
//
//   BalanceCard({
//     required this.name,
//     required this.meals,
//     required this.rate,
//     required this.total,
//     required this.paid,
//     required this.balance,
//     required this.phone,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('$name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Text('M:$meals/R:$rate'),
//             Text('TK:$total/$phone'),
//             Text('Total: $total'),
//             Text('Paid: $paid'),
//             Text('Balance: $balance', style: TextStyle(color: Colors.red)),
//           ],
//         ),
//       ),
//     );
//   }
// }