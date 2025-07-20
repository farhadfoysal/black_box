import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MealCounterPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MealCounterPageState();
  }
}

class MealCounterPageeState  extends State<MealCounterPage>{
  final List<DashboardItem> items = [
    DashboardItem(
      title: 'Tenant Management',
      icon: MdiIcons.officeBuilding,
      color: Colors.blue,
      subtitle: 'Manage Properties & Tenants',
    ),
    DashboardItem(
      title: 'Mess Manager',
      icon: MdiIcons.food,
      color: Colors.orange,
      subtitle: 'Hostel/Dormitory Management',
    ),
    DashboardItem(
      title: 'Tuition Tracker',
      icon: MdiIcons.school,
      color: Colors.green,
      subtitle: 'Track Student Payments',
    ),
    DashboardItem(
      title: 'Tutor Finder',
      icon: MdiIcons.beach,
      color: Colors.purple,
      subtitle: 'Find Qualified Tutors',
    ),
    DashboardItem(
      title: 'Roommate Finder',
      icon: MdiIcons.accountGroup,
      color: Colors.red,
      subtitle: 'Connect with Roommates',
    ),
    DashboardItem(
      title: 'Tuition Finder',
      icon: MdiIcons.magnify,
      color: Colors.teal,
      subtitle: 'Discover Learning Centers',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Your Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: items.map((item) => _buildDashboardItem(item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(DashboardItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Add navigation logic here
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [item.color.withOpacity(0.2), item.color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 40,
                color: item.color,
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class MealCounterPageState extends State<MealCounterPage> {
  // Add these to your state class
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Balance Summary Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('আমার ব্যালেন্স',
                            style: TextStyle(
                                fontSize: 16, color: Colors.teal.shade800)),
                        Text('মোট মিল',
                            style: TextStyle(
                                fontSize: 16, color: Colors.teal.shade800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('৳ ২০.০০',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900)),
                        Text('২.০০',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTransactionTile(
                    icon: Icons.arrow_downward,
                    title: 'আমানত',
                    amount: '৳ ১৫০.০০',
                    color: Colors.green,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildTransactionTile(
                    icon: Icons.arrow_upward,
                    title: 'খরচ',
                    amount: '৳ ১৩০.০০',
                    color: Colors.red,
                  ),
                ],
              ),

              const Divider(height: 32, thickness: 1),

              // Monthly Accounting Table

              Card(
                margin: const EdgeInsets.all(3.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Month Selector Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'মাসিক হিসাব',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                  onPressed: () => _changeMonth(-1),
                                ),
                                InkWell(
                                  onTap: () => _showCustomMonthPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_getMonthName(_currentMonth)}, $_currentYear',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                      ],
                                    ),
                                  ),
                                ),
                                // Text(
                                //   '${_getMonthName(_currentMonth)}, $_currentYear',
                                //   style: const TextStyle(
                                //     fontWeight: FontWeight.w600,
                                //     color: Colors.blue,
                                //   ),
                                // ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                  onPressed: () => _changeMonth(1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Accounting Table
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Table(
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: Colors.grey.shade100),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1),
                            },
                            children: [
                              // Table Rows
                              _buildTableRow('#মোট মিল', '0'),
                              _buildTableRow('#মিল রেট', '0.00'),
                              _buildTableRow('#মিল টাকা', '0.00'),
                              _buildTableRow('#অন্যান্য', '698', isHighlighted: true),
                              _buildTableRow('মোট টাকা', '698', isTotal: true),
                              _buildTableRow('#বাজার খরচ', '0'),
                              _buildTableRow('#পেইড', '0'),
                              _buildTableRow('দিবেন', '698.00', isDue: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              // const Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text('এই মাসের হিসাব',
              //       style: TextStyle(
              //         fontSize: 16,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.indigo,
              //       )),
              // ),
              // const SizedBox(height: 12),
              //
              // Container(
              //   decoration: BoxDecoration(
              //     border: Border.all(color: Colors.grey.shade200),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: DataTable(
              //     headingRowHeight: 0,
              //     dividerThickness: 0,
              //     columnSpacing: 16,
              //     dataRowHeight: 36,
              //     columns: const [
              //       DataColumn(label: SizedBox.shrink()),
              //       DataColumn(label: SizedBox.shrink()),
              //     ],
              //     rows: [
              //       _buildDataRow('#মোট মিল', '0'),
              //       _buildDataRow('#মিল রেট', '0.00'),
              //       _buildDataRow('#মিল টাকা', '0.00'),
              //       _buildDataRow('#অন্যান্য', '698', isHighlighted: true),
              //       _buildDataRow('মোট টাকা', '698', isTotal: true),
              //       _buildDataRow('#বাজার খরচ', '0'),
              //       _buildDataRow('#পেইড', '0'),
              //       _buildDataRow('দিবেন', '698.00', isDue: true),
              //     ],
              //   ),
              // ),
              //


            ],
          ),
        ),
      ),


            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.pink.shade100, Colors.pink.shade50],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friday, Jan 3rd',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade800,
                        ),
                      ),
                      Text(
                        'শুক্রবার, ৩ জানুয়ারি',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.pink.shade700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.pink.shade700),
                    onPressed: () {},
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Bengali Meal Cards
                  MealCard(
                    mealType: 'সকালের খাবার',
                    count: 1,
                    icon: Icons.wb_sunny,
                    color: Colors.orange.shade300,
                  ),
                  SizedBox(height: 12),
                  MealCard(
                    mealType: 'দুপুরের খাবার',
                    count: 0,
                    icon: Icons.sunny,
                    color: Colors.amber.shade300,
                  ),
                  SizedBox(height: 12),
                  MealCard(
                    mealType: 'রাতের খাবার',
                    count: 0,
                    icon: Icons.nightlight_round,
                    color: Colors.indigo.shade300,
                  ),
                  SizedBox(height: 24),

                  // English Meal Cards Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: MealCard1(
                          meal: 'BreakFast',
                          count: 1,
                          color: Colors.lightBlueAccent.withOpacity(0.2),
                          textColor: Colors.lightBlueAccent.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: MealCard1(
                          meal: 'Lunch',
                          count: 0,
                          color: Colors.pinkAccent.withOpacity(0.2),
                          textColor: Colors.pinkAccent.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: MealCard1(
                          meal: 'Dinner',
                          count: 0,
                          color: Colors.cyanAccent.withOpacity(0.2),
                          textColor: Colors.cyanAccent.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
            //   color: Colors.pink[50],
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text(
            //         'Friday, Jan 3rd',
            //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //       ),
            //       IconButton(
            //         icon: Icon(Icons.edit),
            //         onPressed: () {},
            //       ),
            //     ],
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(2.0),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text('শুক্রবার, ৩ জানুয়ারি',
            //           style:
            //               TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            //       SizedBox(height: 20),
            //       MealCard(mealType: 'সকালের খাবার', count: 1),
            //       MealCard(mealType: 'দুপুরের খাবার', count: 0),
            //       MealCard(mealType: 'রাতের খাবার', count: 0),
            //     ],
            //   ),
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: <Widget>[
            //     MealCard1(
            //         meal: 'BreakFast', count: 1, color: Colors.lightBlueAccent),
            //     MealCard1(meal: 'Launch', count: 0, color: Colors.pinkAccent),
            //     MealCard1(meal: 'Dinner', count: 0, color: Colors.cyanAccent),
            //   ],
            // ),

            SchedulePage(),
            MealBoard(),
            MealRecordSection(),
            BazarListSection(),
            MonthlyAccountSection(),
            FinancialSummaryTable(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('দিবেনঃ', style: TextStyle(fontSize: 18)),
                Text('698.00',
                    style: TextStyle(fontSize: 18, color: Colors.pink)),
              ],
            ),
            // BazarListPage1(),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   items: [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //   ],
      // ),
    );
  }

  void _showCustomMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Month and Year'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() => _currentYear--);
                      },
                    ),
                    Text(
                      '$_currentYear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() => _currentYear++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Month grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  children: List.generate(12, (index) {
                    final month = index + 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentMonth = month;
                          Navigator.pop(context);
                          // Fetch data for new month
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _currentMonth == month
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _currentMonth == month
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getMonthName(month),
                            style: TextStyle(
                              fontWeight: _currentMonth == month
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _currentMonth == month
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_currentYear, _currentMonth),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentMonth = picked.month;
        _currentYear = picked.year;
        // Here you would typically fetch data for the new month
      });
    }
  }


  String _getMonthName(int month) {
    const months = [
      'জানুয়ারী', 'ফেব্রুয়ারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    return months[month - 1];
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
      // Here you would typically fetch data for the new month
    });
  }

  TableRow _buildTableRow(String label, String value, {
    bool isHighlighted = false,
    bool isTotal = false,
    bool isDue = false,
  }) {
    final textColor = isDue ? Colors.red.shade700 :
    isTotal ? Colors.green.shade700 :
    isHighlighted ? Colors.orange.shade700 : Colors.grey.shade800;

    final bgColor = isTotal ? Colors.green.shade50 :
    isDue ? Colors.red.shade50 :
    isHighlighted ? Colors.orange.shade50 : Colors.transparent;

    return TableRow(
      decoration: BoxDecoration(
        color: bgColor,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isHighlighted || isTotal || isDue
                  ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: isTotal || isDue ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget for Transaction Tile
  Widget _buildTransactionTile({
    required IconData icon,
    required String title,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            )),
      ],
    );
  }

// Helper Method for Data Rows
  DataRow _buildDataRow(String label, String value, {
    bool isHighlighted = false,
    bool isTotal = false,
    bool isDue = false,
  }) {
    return DataRow(
      cells: [
        DataCell(Text(
          label,
          style: TextStyle(
            color: isHighlighted ? Colors.orange.shade800 : Colors.grey.shade700,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        )),
        DataCell(Text(
          value,
          style: TextStyle(
            color: isDue ? Colors.red :
            isTotal ? Colors.green.shade800 : Colors.grey.shade800,
            fontWeight: isTotal || isDue ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.end,
        )),
      ],
    );
  }

}

class MealCard extends StatelessWidget {
  final String mealType;
  final int count;
  final IconData icon;
  final Color color;

  const MealCard({
    required this.mealType,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                mealType,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealCard1 extends StatelessWidget {
  final String meal;
  final int count;
  final Color color;
  final Color textColor;

  const MealCard1({
    required this.meal,
    required this.count,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              meal,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealRecordSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'আজকের মিল বোর্ড',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Friday, Jan 3rd',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  MealRecordRow(
                    mealType: 'সকালের খাবার:',
                    count: '00',
                    icon: Icons.sunny,
                    color: Colors.orange.shade400,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  MealRecordRow(
                    mealType: 'দুপুরের খাবার:',
                    count: '00',
                    icon: Icons.wb_sunny_outlined,
                    color: Colors.amber.shade600,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  MealRecordRow(
                    mealType: 'রাতের খাবার:',
                    count: '00',
                    icon: Icons.nightlight_round,
                    color: Colors.indigo.shade400,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade400, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NO Record Found! Or You are not added by any mess!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealRecordRow extends StatelessWidget {
  final String mealType;
  final String count;
  final IconData icon;
  final Color color;

  MealRecordRow({
    required this.mealType,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              SizedBox(width: 12),
              Text(
                mealType,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: count == '00' ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: count == '00' ? Colors.red.shade600 : Colors.green.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class MealRecordSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           Text(
//             'আজকের মিল বোর্ড: Friday, Jan 3rd',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8.0),
//           MealRecordRow(mealType: 'সকালের খাবার:', count: '00'),
//           MealRecordRow(mealType: 'দুপুরের খাবার:', count: '00'),
//           MealRecordRow(mealType: 'রাতের খাবার:', count: '00'),
//           SizedBox(height: 8.0),
//           Text(
//             'NO Record Found! Or You are not added by any mess!',
//             style: TextStyle(fontSize: 14, color: Colors.red),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class MealRecordRow extends StatelessWidget {
//   final String mealType;
//   final String count;
//   MealRecordRow({required this.mealType, required this.count});
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(mealType, style: TextStyle(fontSize: 16)),
//         Text(count, style: TextStyle(fontSize: 16)),
//       ],
//     );
//   }
// }

class BazarListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('January ~ Bazar List:'),
      children: [
        ListTile(
          title: Text('No items in the bazar list.'),
        ),
      ],
    );
  }
}

class MonthlyAccountSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('এই মাসের হিসাব'),
      children: [
        ListTile(
          title: Text('No records found.'),
        ),
      ],
    );
  }
}

// class MealCard extends StatelessWidget {
//   final String mealType;
//   final int count;
//   MealCard({required this.mealType, required this.count});
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 2),
//       child: ListTile(
//         title: Text(mealType, style: TextStyle(fontSize: 18)),
//         trailing: CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Text(count.toString(), style: TextStyle(color: Colors.white)),
//         ),
//       ),
//     );
//   }
// }
//
// class MealCard1 extends StatelessWidget {
//   final String meal;
//   final int count;
//   final Color color;
//   MealCard1({required this.meal, required this.count, required this.color});
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: color,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             Text(
//               meal,
//               style: TextStyle(fontSize: 20),
//             ),
//             SizedBox(height: 8),
//             Text(
//               count.toString(),
//               style: TextStyle(fontSize: 24),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class MealBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade100, Colors.blue.shade50],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'আজকের মিল বোর্ড',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Friday, Jan 3rd',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                      },
                      children: [
                        // Header Row
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          children: [
                            _buildHeaderCell('No./Name'),
                            _buildHeaderCell('BreakFast'),
                            _buildHeaderCell('Launch'),
                            _buildHeaderCell('Dinner'),
                            _buildHeaderCell('Total'),
                          ],
                        ),
                        // Data Row
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          children: [
                            _buildDataCell('1#F Foysal', isName: true),
                            _buildDataCell('1', isPresent: true),
                            _buildDataCell('0', isAbsent: true),
                            _buildDataCell('0', isAbsent: true),
                            _buildDataCell('1', isTotal: true),
                          ],
                        ),
                        // Add more rows as needed
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'January ~ Bazar List:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: Colors.blue.shade700),
                      onPressed: () {
                        // Add new bazar item
                      },
                    ),
                  ],
                ),
                // Add bazar list items here
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {
    bool isName = false,
    bool isPresent = false,
    bool isAbsent = false,
    bool isTotal = false,
  }) {
    Color textColor = Colors.grey.shade800;
    FontWeight fontWeight = FontWeight.normal;

    if (isName) {
      textColor = Colors.blue.shade700;
      fontWeight = FontWeight.w500;
    } else if (isPresent) {
      textColor = Colors.green.shade600;
    } else if (isAbsent) {
      textColor = Colors.orange.shade600;
    } else if (isTotal) {
      textColor = Colors.blue.shade800;
      fontWeight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Widget build(BuildContext context) {
  //   return SingleChildScrollView(
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: EdgeInsets.all(10),
  //           color: Colors.blue[50],
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'আজকের মিল বোর্ড: Friday, Jan 3rd',
  //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //               ),
  //               SizedBox(height: 10),
  //               Table(
  //                 border: TableBorder.all(),
  //                 children: [
  //                   TableRow(
  //                     children: [
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('No./Name',
  //                             style: TextStyle(fontWeight: FontWeight.bold)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('BreakFast',
  //                             style: TextStyle(fontWeight: FontWeight.bold)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('Launch',
  //                             style: TextStyle(fontWeight: FontWeight.bold)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('Dinner',
  //                             style: TextStyle(fontWeight: FontWeight.bold)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('Total',
  //                             style: TextStyle(fontWeight: FontWeight.bold)),
  //                       ),
  //                     ],
  //                   ),
  //                   TableRow(
  //                     children: [
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('1#F Foysal',
  //                             style: TextStyle(color: Colors.blue)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child:
  //                             Text('1', style: TextStyle(color: Colors.green)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child:
  //                             Text('0', style: TextStyle(color: Colors.yellow)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('0', style: TextStyle(color: Colors.red)),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Text('1'),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 20),
  //               Text(
  //                 'January ~ Bazar List:',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class SchedulePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add New Schedule Button
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.add_circle_outline, size: 40, color: Colors.blue.shade700),
              SizedBox(height: 8),
              Text(
                'Add New Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ).addPressEffect(),

        // Schedule Entries
        ScheduleEntry(
          date: '3rd Jan, 2025',
          morning: 1,
          afternoon: 0,
          night: 0,
        ),
        ScheduleEntry(
          date: '5th Jan, 2025',
          morning: 2,
          afternoon: 1,
          night: 2,
        ),
      ],
    );
  }
}

class ScheduleEntry extends StatelessWidget {
  final String date;
  final int morning;
  final int afternoon;
  final int night;

  ScheduleEntry({
    required this.date,
    required this.morning,
    required this.afternoon,
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 18, color: Colors.blue.shade600),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Time Slots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TimeSlot(
                  label: 'সকাল',
                  value: morning,
                  icon: Icons.wb_sunny,
                  color: Colors.orange.shade400,
                ),
                TimeSlot(
                  label: 'দুপুর',
                  value: afternoon,
                  icon: Icons.sunny,
                  color: Colors.amber.shade600,
                ),
                TimeSlot(
                  label: 'রাত',
                  value: night,
                  icon: Icons.nightlight_round,
                  color: Colors.indigo.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSlot extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  TimeSlot({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: value > 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: value > 0 ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

// Extension for press effect
extension PressEffect on Widget {
  Widget addPressEffect() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: this,
    );
  }
}


class BazarListPage1 extends StatelessWidget {
  final List<Map<String, String>> bazarList = [
    {'name': 'Rafsan', 'from': 'From 3rd Mar', 'to': 'End 5th Mar'},
    {'name': 'Adnan', 'from': 'From 6th Mar', 'to': 'End 8th Mar'},
    {'name': 'Omi', 'from': 'From 9th Mar', 'to': 'End 11th Mar'},
    {'name': 'Raihan', 'from': 'From 12th Mar', 'to': 'End 14th Mar'},
    {'name': 'Tamim', 'from': 'From 15th Mar', 'to': 'End 17th Mar'},
    {'name': 'AmzadHosaain', 'from': 'From 18th Mar', 'to': 'End 20th Mar'},
    {'name': 'Zubair', 'from': 'From 21st Mar', 'to': 'End 23rd Mar'},
    {'name': 'Tarek', 'from': 'From 24th Mar', 'to': 'End 26th Mar'},
    {'name': 'F Foysal', 'from': 'From 27th Mar', 'to': 'End 29th Mar'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('January ~ Bazar List',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial Summary Card
          Card(
            margin: EdgeInsets.all(16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  SizedBox(height: 12),
                  FinancialSummaryTable(),
                ],
              ),
            ),
          ),

          // Bazar List
          Expanded(
            child: ListView.builder(
              itemCount: bazarList.length,
              itemBuilder: (context, index) {
                final item = bazarList[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        item['name']!.substring(0, 1),
                        style: TextStyle(color: Colors.teal.shade800),
                      ),
                    ),
                    title: Text(
                      item['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${item['from']} - ${item['to']}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue.shade600),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.lock, color: Colors.grey.shade600),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FinancialSummaryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      children: [
        _buildTableRow('#মোট মিলঃ', '1'),
        _buildTableRow('#মিল রেইটঃ', '0.00'),
        _buildTableRow('#মিল টাকারঃ', '0.00'),
        _buildTableRow('#অন্যায়ঃ', '698', isHighlighted: true),
        _buildTableRow('মোট টাকারঃ', '698', isTotal: true),
        _buildTableRow('বাজার খরচঃ', '0'),
        _buildTableRow('#পেইডঃ', '0'),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, {bool isHighlighted = false, bool isTotal = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isTotal ? Colors.teal.shade50 : Colors.transparent,
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isHighlighted ? Colors.orange.shade800 : Colors.grey.shade700,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isTotal ? Colors.teal.shade800 : Colors.grey.shade800,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}


// class SchedulePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           margin: EdgeInsets.all(10),
//           padding: EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.blue),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(Icons.add, size: 50, color: Colors.blue),
//         ),
//         ScheduleEntry(
//           date: '3rd Jan, 2025',
//           morning: 1,
//           afternoon: 0,
//           night: 0,
//         ),
//         ScheduleEntry(
//           date: '5th Jan, 2025',
//           morning: 2,
//           afternoon: 1,
//           night: 2,
//         ),
//       ],
//     );
//   }
// }
//
// class ScheduleEntry extends StatelessWidget {
//   final String date;
//   final int morning;
//   final int afternoon;
//   final int night;
//   ScheduleEntry(
//       {required this.date,
//       required this.morning,
//       required this.afternoon,
//       required this.night});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//       padding: EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         children: [
//           Text(
//             date,
//             style: TextStyle(
//                 fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               TimeSlot(label: 'সকাল', value: morning, color: Colors.lightBlue),
//               TimeSlot(
//                   label: 'দুপুর', value: afternoon, color: Colors.pinkAccent),
//               TimeSlot(label: 'রাত', value: night, color: Colors.teal),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class TimeSlot extends StatelessWidget {
//   final String label;
//   final int value;
//   final Color color;
//   TimeSlot({required this.label, required this.value, required this.color});
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: TextStyle(fontSize: 16, color: color),
//         ),
//         SizedBox(height: 5),
//         Text(
//           value.toString(),
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }
// }

// class BazarListPage1 extends StatelessWidget {
//   final List<Map<String, String>> bazarList = [
//     {'name': 'Rafsan', 'from': 'From 3rd Mar', 'to': 'End 5th Mar'},
//     {'name': 'Adnan', 'from': 'From 6th Mar', 'to': 'End 8th Mar'},
//     {'name': 'Omi', 'from': 'From 9th Mar', 'to': 'End 11th Mar'},
//     {'name': 'Raihan', 'from': 'From 12th Mar', 'to': 'End 14th Mar'},
//     {'name': 'Tamim', 'from': 'From 15th Mar', 'to': 'End 17th Mar'},
//     {'name': 'AmzadHosaain', 'from': 'From 18th Mar', 'to': 'End 20th Mar'},
//     {'name': 'Zubair', 'from': 'From 21st Mar', 'to': 'End 23rd Mar'},
//     {'name': 'Tarek', 'from': 'From 24th Mar', 'to': 'End 26th Mar'},
//     {'name': 'F Foysal', 'from': 'From 27th Mar', 'to': 'End 29th Mar'},
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('January ~ Bazar List'),
//       ),
//       body: ListView.builder(
//         itemCount: bazarList.length,
//         itemBuilder: (context, index) {
//           final item = bazarList[index];
//           return Card(
//             margin: EdgeInsets.all(8.0),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundImage: AssetImage('assets/profile.png'),
//               ),
//               title: Text(item['name']!),
//               subtitle: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['from']!),
//                   Text(item['to']!),
//                 ],
//               ),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.edit),
//                     onPressed: () {},
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.lock),
//                     onPressed: () {},
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class FinancialSummaryTable extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return DataTable(
//       columns: [
//         DataColumn(label: Text('ধরনঃ')),
//         DataColumn(label: Text('টাকাঃ')),
//       ],
//       rows: [
//         DataRow(cells: [
//           DataCell(Text('#মোট মিলঃ')),
//           DataCell(Text('1')),
//         ]),
//         DataRow(cells: [
//           DataCell(Text('#মিল রেইটঃ')),
//           DataCell(Text('0.00')),
//         ]),
//         DataRow(cells: [
//           DataCell(Text('#মিল টাকারঃ')),
//           DataCell(Text('0.00')),
//         ]),
//         DataRow(cells: [
//           DataCell(Text('#অন্যায়ঃ')),
//           DataCell(Text('698')),
//         ]),
//         DataRow(cells: [
//           DataCell(Text('মোট টাকারঃ')),
//           DataCell(Text('698')),
//         ]),
//         DataRow(cells: [
//           DataCell(Text('বাজার খরচঃ')),
//           DataCell(Text('0')),
//         ]),
//         DataRow(cells: [
//           DataCell(Text('#পেইডঃ')),
//           DataCell(Text('0')),
//         ]),
//       ],
//     );
//   }
// }
