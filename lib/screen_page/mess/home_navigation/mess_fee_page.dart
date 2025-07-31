import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';

class MessFeePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MessFeePageState();
}

class MessFeePageState extends State<MessFeePage> {
  bool _darkMode = false;
  final Color _primaryColor = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkMode
          ? ThemeData.dark().copyWith(primaryColor: _primaryColor)
          : ThemeData.light().copyWith(primaryColor: _primaryColor),
      child: Scaffold(
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
                      text: "Fee Management",
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
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                DatePickerSection(),
                SizedBox(height: 16),
                UserListSection(),
                SizedBox(height: 16),
                MonthlySummarySection(),
                SizedBox(height: 16),
                FeeListSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DatePickerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Select Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                readOnly: true,
                controller: TextEditingController(text: '03/01/2025'),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: Text('CHECK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class UserListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Members Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          ...List.generate(6, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                margin: EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Theme.of(context).cardColor.withOpacity(0.7),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    backgroundImage: AssetImage('assets/background.jpg'),
                  ),
                  title: Text('User ${index + 1}', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('2025-01-03', style: TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MealIndicator('B', Colors.green),
                      SizedBox(width: 4),
                      _MealIndicator('L', Colors.orange),
                      SizedBox(width: 4),
                      _MealIndicator('D', Colors.blue),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MealIndicator extends StatelessWidget {
  final String text;
  final Color color;

  const _MealIndicator(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withOpacity(0.2),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class MonthlySummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Monthly Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 8,
              dataRowHeight: 40,
              columns: [
                DataColumn(
                  label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                ),
              ],
              rows: [
                _buildDataRow('Total Meals', '0'),
                _buildDataRow('Meal Rate', '0.00'),
                _buildDataRow('Meal Cost', '0.00'),
                _buildDataRow('Others', '698', isHighlighted: true),
                _buildDataRow('Total Amount', '698', isHighlighted: true),
                _buildDataRow('Bazar Cost', '0'),
                _buildDataRow('Paid', '0'),
                _buildDataRow('Due', '698.00', isHighlighted: true),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String label, String value, {bool isHighlighted = false}) {
    return DataRow(
      cells: [
        DataCell(Text(
          label,
          style: TextStyle(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        )),
        DataCell(Text(
          value,
          style: TextStyle(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.deepPurple : null,
          ),
        )),
      ],
    );
  }
}

class FeeListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.03),
                Theme.of(context).primaryColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.receipt,
                        color: Theme.of(context).primaryColor, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Fee Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Table with horizontal scroll for smaller devices
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 12,
                    headingRowHeight: 40,
                    dataRowHeight: 48,
                    dividerThickness: 0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    columns: [
                      DataColumn(
                        label: _TableHeader('#'),
                      ),
                      DataColumn(
                        label: _TableHeader('FEE TYPE'),
                      ),
                      DataColumn(
                        label: _TableHeader('AMOUNT'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: _TableHeader('ACTION'),
                      ),
                    ],
                    rows: [
                      _buildFeeRow('1', '50 extra', '50', context),
                      _buildFeeRow('2', 'Wifi', '133', context),
                      _buildFeeRow('3', 'Current-bill', '112', context),
                      _buildFeeRow('4', 'Bua-bill', '333', context),
                      _buildFeeRow('5', 'Gas-bill', '120', context),
                    ],
                  ),
                ),
              ),

              // Summary section with better visual hierarchy
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context: context,
                      icon: Icons.calculate,
                      label: 'Total:',
                      value: '748/=',
                      isHighlighted: true,
                    ),
                    Divider(height: 20, thickness: 0.5),
                    _buildSummaryRow(
                      context: context,
                      icon: Icons.restaurant,
                      label: 'Meal:',
                      value: '6.00টি, 0.00/=',
                    ),
                    SizedBox(height: 8),
                    _buildSummaryRow(
                      context: context,
                      icon: Icons.summarize,
                      label: 'Sub Total:',
                      value: '748.00/=',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),

              // Pay Now button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'PAY NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildFeeRow(String id, String type, String amount, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              id,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            type,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            '\$$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: Icon(Icons.more_vert, size: 20),
            onPressed: () {
              _showFeeOptions(context, id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,  // Add this parameter
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isHighlighted
                  ? Theme.of(context).primaryColor
                  : Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeeOptions(BuildContext context, String feeId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.receipt_long,
                    color: Theme.of(context).primaryColor),
                title: Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  // View details logic
                },
              ),
              ListTile(
                leading: Icon(Icons.edit,
                    color: Theme.of(context).primaryColor),
                title: Text('Edit Fee'),
                onTap: () {
                  Navigator.pop(context);
                  // Edit logic
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Delete logic
                },
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }
}

// class FeeListSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//             child: Text(
//               'Fee Details',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: DataTable(
//               columnSpacing: 16,
//               horizontalMargin: 8,
//               columns: [
//                 DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
//                 DataColumn(label: Text('FEE TYPE', style: TextStyle(fontWeight: FontWeight.bold))),
//                 DataColumn(
//                   label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
//                   numeric: true,
//                 ),
//               ],
//               rows: [
//                 _buildFeeRow('1', '50 extra', '50'),
//                 _buildFeeRow('2', 'Wifi', '133'),
//                 _buildFeeRow('3', 'Current-bill', '112'),
//                 _buildFeeRow('4', 'Bua-bill', '333'),
//                 _buildFeeRow('5', 'Gas-bill', '120'),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildSummaryRow('Total:', '748/=', isHighlighted: true),
//                 _buildSummaryRow('Meal:', '6.00টি, 0.00/=', isHighlighted: false),
//                 _buildSummaryRow('Sub Total:', '748.00/=', isHighlighted: true),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   DataRow _buildFeeRow(String id, String type, String amount) {
//     return DataRow(
//       cells: [
//         DataCell(Text(id)),
//         DataCell(Text(type)),
//         DataCell(Text(amount, style: TextStyle(fontWeight: FontWeight.w500))),
//       ],
//     );
//   }
//
//   Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
//               color: isHighlighted ? Colors.deepPurple : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
//
// class MessFeePage extends StatefulWidget{
//   @override
//   State<StatefulWidget> createState() {
//     return MessFeePageState();
//   }
//
// }
//
// class MessFeePageState extends State<MessFeePage>{
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Flutter App'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.nightlight_round),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             DatePickerSection(),
//             UserListSection(),
//             MonthlySummarySection(),
//             FeeListSection(),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
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