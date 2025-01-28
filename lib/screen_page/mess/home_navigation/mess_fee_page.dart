import 'package:flutter/material.dart';

class MessFeePage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MessFeePageState();
  }

}

class MessFeePageState extends State<MessFeePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter App'),
        actions: [
          IconButton(
            icon: Icon(Icons.nightlight_round),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DatePickerSection(),
            UserListSection(),
            MonthlySummarySection(),
            FeeListSection(),
          ],
        ),
      ),
    );
  }
}

class DatePickerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '03/01/2025',
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            child: Text('CHECK'),
          ),
        ],
      ),
    );
  }
}

class UserListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (index) {
        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            title: Text('User Name'),
            subtitle: Text('2025-01-03'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text('B'),
                ),
                SizedBox(width: 4),
                CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text('L'),
                ),
                SizedBox(width: 4),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text('D'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class MonthlySummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text('এই মাসের হিসাব', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataTable(
            columns: [
              DataColumn(label: Text('ধরন')),
              DataColumn(label: Text('টাকা')),
            ],
            rows: [
              DataRow(cells: [DataCell(Text('#মোট মিল')), DataCell(Text('0'))]),
              DataRow(cells: [DataCell(Text('#মিল রেট')), DataCell(Text('0.00'))]),
              DataRow(cells: [DataCell(Text('#মিল টাকা')), DataCell(Text('0.00'))]),
              DataRow(cells: [DataCell(Text('#অন্যান্য')), DataCell(Text('698'))]),
              DataRow(cells: [DataCell(Text('মোট টাকা')), DataCell(Text('698'))]),
              DataRow(cells: [DataCell(Text('#বাজার খরচ')), DataCell(Text('0'))]),
              DataRow(cells: [DataCell(Text('#পেইড')), DataCell(Text('0'))]),
              DataRow(cells: [DataCell(Text('দিবেন')), DataCell(Text('698.00'))]),
            ],
          ),
        ],
      ),
    );
  }
}

class FeeListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text('Mess Fee Lists', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataTable(
            columns: [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('FEE TYPE')),
              DataColumn(label: Text('AMOUNT')),
            ],
            rows: [
              DataRow(cells: [DataCell(Text('1')), DataCell(Text('50 extra')), DataCell(Text('50'))]),
              DataRow(cells: [DataCell(Text('2')), DataCell(Text('Wifi')), DataCell(Text('133'))]),
              DataRow(cells: [DataCell(Text('3')), DataCell(Text('Current-bill')), DataCell(Text('112'))]),
              DataRow(cells: [DataCell(Text('4')), DataCell(Text('Bua-bill')), DataCell(Text('333'))]),
              DataRow(cells: [DataCell(Text('5')), DataCell(Text('Gas-bill')), DataCell(Text('120'))]),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total: 748/='),
                Text('Meal: 6.00টি, 0.00/='),
                Text('Sub Total: 748.00/='),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// class DatePickerSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 labelText: '03/01/2025',
//                 labelStyle: TextStyle(color: Colors.blue),
//               ),
//             ),
//           ),
//           SizedBox(width: 8),
//           ElevatedButton(
//             onPressed: () {},
//             child: Text('CHECK'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class UserListSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: List.generate(6, (index) {
//         return Card(
//           margin: EdgeInsets.all(8.0),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundImage: AssetImage('assets/avatar.png'),
//             ),
//             title: Text('User Name'),
//             subtitle: Text('2025-01-03'),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.green,
//                   child: Text('B'),
//                 ),
//                 SizedBox(width: 4),
//                 CircleAvatar(
//                   backgroundColor: Colors.red,
//                   child: Text('L'),
//                 ),
//                 SizedBox(width: 4),
//                 CircleAvatar(
//                   backgroundColor: Colors.blue,
//                   child: Text('D'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }
//
// class MonthlySummarySection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       child: Column(
//         children: [
//           ListTile(
//             title: Text('এই মাসের হিসাব', style: TextStyle(fontWeight: FontWeight.bold)),
//           ),
//           DataTable(
//             columns: [
//               DataColumn(label: Text('ধরন')),
//               DataColumn(label: Text('টাকা')),
//             ],
//             rows: [
//               DataRow(cells: [DataCell(Text('#মোট মিল')), DataCell(Text('0'))]),
//               DataRow(cells: [DataCell(Text('#মিল রেট')), DataCell(Text('0.00'))]),
//               DataRow(cells: [DataCell(Text('#মিল টাকা')), DataCell(Text('0.00'))]),
//               DataRow(cells: [DataCell(Text('#অন্যান্য')), DataCell(Text('698'))]),
//               DataRow(cells: [DataCell(Text('মোট টাকা')), DataCell(Text('698'))]),
//               DataRow(cells: [DataCell(Text('#বাজার খরচ')), DataCell(Text('0'))]),
//               DataRow(cells: [DataCell(Text('#পেইড')), DataCell(Text('0'))]),
//               DataRow(cells: [DataCell(Text('দিবেন')), DataCell(Text('698.00'))]),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class FeeListSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       child: Column(
//         children: [
//           ListTile(
//             title: Text('Mess Fee Lists', style: TextStyle(fontWeight: FontWeight.bold)),
//           ),
//           DataTable(
//             columns: [
//               DataColumn(label: Text('#')),
//               DataColumn(label: Text('FEE TYPE')),
//               DataColumn(label: Text('AMOUNT')),
//             ],
//             rows: [
//               DataRow(cells: [DataCell(Text('1')), DataCell(Text('50 extra')), DataCell(Text('50'))]),
//               DataRow(cells: [DataCell(Text('2')), DataCell(Text('Wifi')), DataCell(Text('133'))]),
//               DataRow(cells: [DataCell(Text('3')), DataCell(Text('Current-bill')), DataCell(Text('112'))]),
//               DataRow(cells: [DataCell(Text('4')), DataCell(Text('Bua-bill')), DataCell(Text('333'))]),
//               DataRow(cells: [DataCell(Text('5')), DataCell(Text('Gas-bill')), DataCell(Text('120'))]),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Total: 748/='),
//                 Text('Meal: 6.00টি, 0.00/='),
//                 Text('Sub Total: 748.00/='),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }