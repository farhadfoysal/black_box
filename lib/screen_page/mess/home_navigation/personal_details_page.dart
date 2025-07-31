import 'package:black_box/screen_page/mess/home_navigation/profile_flip_card.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';

import '../../../model/mess/mess_main.dart';
import '../../../model/mess/mess_user.dart';

class PersonalDetailsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PersonalDetailsPageState();
  }
}

class PersonalDetailsPageState extends State<PersonalDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.indigo.shade100,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade100,
                ),
                child: Icon(Icons.code_rounded,
                    size: 16,
                    color: Colors.indigo.shade800),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.indigo.shade800,
                  highlightColor: Colors.indigo.shade400,
                  child: Marquee(
                    text: "আমার ওয়ালেট",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade800,
                    ),
                    scrollAxis: Axis.horizontal,
                    blankSpace: 40.0,
                    velocity: 60.0,
                    pauseAfterRound: Duration(seconds: 2),
                    startPadding: 20.0,
                    accelerationDuration: Duration(seconds: 1),
                    decelerationDuration: Duration(milliseconds: 500),
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C6AB), Color(0xFF0082A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlipCard(
              user: MessUser(
                userId: "John Doe",
                phone: "+8801712345678",
                email: "john.doe@example.com",
                uniqueId: "USER12345",
              ),
              messInfo: MessMain(
                messName: "Delicious Food Mess",
                messId: "MESS001",
                messAddress: "123 Food Street",
              ),
              currentManagerName: "Jane Smith",
              currentManagerPhone: "+8801812345678",
            ),
            WalletSummary(),
            SizedBox(height: 16),
            TransactionHistory(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xFF0082A8),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'হোম',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'ড্যাশবোর্ড',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'কাউন্টার',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'সেটিংস',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFF00C6AB), Color(0xFF0082A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'আমার ব্যালেন্স',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'মোট মিল',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '৳ ২০.০০',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '২.০০',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.3), height: 1),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  icon: Icons.arrow_downward,
                  label: 'আমার আমানত',
                  amount: '৳ ১৫০.০০',
                  color: Colors.white,
                ),
                _buildStatItem(
                  icon: Icons.arrow_upward,
                  label: 'আমার খরচ',
                  amount: '৳ ১৩০.০০',
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class TransactionHistory extends StatelessWidget {
  final List<Map<String, dynamic>> transactions = [
    {
      'title': 'টাকা জমা',
      'date': '২০২৫-০১-০৪',
      'amount': '৫০.০০ ৳',
      'type': 'deposit',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'বিল পেমেন্ট',
      'date': '২০২৫-০১-০৩',
      'amount': '৩০.০০ ৳',
      'type': 'withdraw',
      'icon': Icons.receipt,
    },
    {
      'title': 'মোবাইল রিচার্জ',
      'date': '২০২৫-০১-০২',
      'amount': '১০০.০০ ৳',
      'type': 'withdraw',
      'icon': Icons.phone_android,
    },
    {
      'title': 'টাকা জমা',
      'date': '২০২৫-০১-০১',
      'amount': '২০০.০০ ৳',
      'type': 'deposit',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'শপিং পেমেন্ট',
      'date': '২০২৪-১২-৩০',
      'amount': '১৫০.০০ ৳',
      'type': 'withdraw',
      'icon': Icons.shopping_cart,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ট্রানজেকশন হিস্ট্রি',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: transaction['type'] == 'deposit'
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    transaction['icon'],
                    color: transaction['type'] == 'deposit'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                title: Text(
                  transaction['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  transaction['date'],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                trailing: Text(
                  transaction['amount'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction['type'] == 'deposit'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                minLeadingWidth: 0,
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {},
              child: Text(
                'সব দেখুন',
                style: TextStyle(
                  color: Color(0xFF0082A8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// import 'package:flutter/material.dart';
//
// class PersonalDetailsPage extends StatefulWidget{
//   @override
//   State<StatefulWidget> createState() {
//    return PersonalDetailsPageState();
//   }
//
// }
//
// class PersonalDetailsPageState extends State<PersonalDetailsPage>{
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('আমার ওয়ালেট'),
//         leading: Icon(Icons.arrow_back),
//         actions: [
//           Icon(Icons.notifications),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             WalletSummary(),
//             TransactionHistory(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'হোম'),
//           BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ড্যাশবোর্ড'),
//           BottomNavigationBarItem(icon: Icon(Icons.people), label: 'কাউন্টার'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'সেটিংস'),
//         ],
//       ),
//     );
//   }
// }
//
// class WalletSummary extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('আমার ব্যালেন্স', style: TextStyle(fontSize: 16)),
//                 Text('মোট মিল', style: TextStyle(fontSize: 16)),
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('৳ ২০.০০', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                 Text('২.০০', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             Divider(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   children: [
//                     Icon(Icons.arrow_downward, color: Colors.teal),
//                     Text('আমার আমানত'),
//                     Text('৳ ১৫০.০০', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Icon(Icons.arrow_upward, color: Colors.teal),
//                     Text('আমার খরচ'),
//                     Text('৳ ১৩০.০০', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class TransactionHistory extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: List.generate(5, (index) {
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundColor: Colors.blue,
//             child: Icon(Icons.person, color: Colors.white),
//           ),
//           title: Text('টাকা জমা'),
//           subtitle: Text('২০২৫-০১-০৪'),
//           trailing: Text('৫০.০০ ৳', style: TextStyle(fontWeight: FontWeight.bold)),
//         );
//       }),
//     );
//   }
// }