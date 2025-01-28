import 'package:flutter/material.dart';

class BazarExpense extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return BazarExpenseState();
  }

}

class BazarExpenseState extends State<BazarExpense>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Balance List'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {},
          ),
          CircleAvatar(
            backgroundImage: AssetImage('assets/avatar.png'),
          ),
          SizedBox(width: 8),
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

  BalanceCard({
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
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('M:$meals/R:$rate'),
            Text('TK:$total/$phone'),
            Text('Total: $total'),
            Text('Paid: $paid'),
            Text('Balance: $balance', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}