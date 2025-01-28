import 'package:flutter/material.dart';

class MessSettings extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MessSettingsState();
  }

}

class MessSettingsState extends State<MessSettings>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ff'),
        leading: Icon(Icons.menu),
        actions: [
          Icon(Icons.person_add),
          SizedBox(width: 8),
          Icon(Icons.picture_as_pdf),
          SizedBox(width: 8),
          Stack(
            children: [
              Icon(Icons.notifications),
              Positioned(
                right: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text('4', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            UserProfile(),
            WalletCard(),
            OperationsSection(),
            TransactionHistory(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'হোম'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ড্যাশবোর্ড'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'কাউন্টার'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'সেটিংস'),
        ],
      ),
    );
  }
}

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text('farhad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      subtitle: Text('Jan 2025', style: TextStyle(color: Colors.blue)),
    );
  }
}

class WalletCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('মেস ব্যালেন্স', style: TextStyle(color: Colors.white, fontSize: 16)),
                Icon(Icons.sync, color: Colors.white),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('৳ ২০.০০', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.orange),
                        Text(' জমা', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Text('৳ ১৫০.০০', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.orange),
                        Text(' ব্যয়', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Text('৳ ১৩০.০০', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

class OperationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('অপারেশন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                OperationIcon(icon: Icons.account_balance_wallet, label: 'আমার ওয়ালেট'),
                OperationIcon(icon: Icons.list, label: 'মিলের তালিকা'),
                OperationIcon(icon: Icons.shopping_cart, label: 'বাজারের তারিখ'),
                OperationIcon(icon: Icons.money, label: 'সমস্ত খরচ'),
                OperationIcon(icon: Icons.wallet_travel, label: 'মেস ওয়ালেট'),
                OperationIcon(icon: Icons.picture_as_pdf, label: 'ডকুমেন্টস'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OperationIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  OperationIcon({required this.icon, required this.label});

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

class TransactionHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text('টাকা জমা'),
          subtitle: Text('২০২৫-০১-০৪'),
          trailing: Text('৫০.০০ ৳', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }),
    );
  }
}