import 'package:flutter/material.dart';

class PersonalDetailsPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
   return PersonalDetailsPageState();
  }

}

class PersonalDetailsPageState extends State<PersonalDetailsPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('আমার ওয়ালেট'),
        leading: Icon(Icons.arrow_back),
        actions: [
          Icon(Icons.notifications),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            WalletSummary(),
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

class WalletSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('আমার ব্যালেন্স', style: TextStyle(fontSize: 16)),
                Text('মোট মিল', style: TextStyle(fontSize: 16)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('৳ ২০.০০', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('২.০০', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.teal),
                    Text('আমার আমানত'),
                    Text('৳ ১৫০.০০', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.teal),
                    Text('আমার খরচ'),
                    Text('৳ ১৩০.০০', style: TextStyle(fontWeight: FontWeight.bold)),
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

class TransactionHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
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