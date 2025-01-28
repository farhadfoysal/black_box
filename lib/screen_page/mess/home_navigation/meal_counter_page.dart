import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MealCounterPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MealCounterPageeState();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
              color: Colors.pink[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Friday, Jan 3rd',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('শুক্রবার, ৩ জানুয়ারি',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  MealCard(mealType: 'সকালের খাবার', count: 1),
                  MealCard(mealType: 'দুপুরের খাবার', count: 0),
                  MealCard(mealType: 'রাতের খাবার', count: 0),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                MealCard1(
                    meal: 'BreakFast', count: 1, color: Colors.lightBlueAccent),
                MealCard1(meal: 'Launch', count: 0, color: Colors.pinkAccent),
                MealCard1(meal: 'Dinner', count: 0, color: Colors.cyanAccent),
              ],
            ),

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
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
        ],
      ),
    );
  }
}

class MealRecordSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'আজকের মিল বোর্ড: Friday, Jan 3rd',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.0),
          MealRecordRow(mealType: 'সকালের খাবার:', count: '00'),
          MealRecordRow(mealType: 'দুপুরের খাবার:', count: '00'),
          MealRecordRow(mealType: 'রাতের খাবার:', count: '00'),
          SizedBox(height: 8.0),
          Text(
            'NO Record Found! Or You are not added by any mess!',
            style: TextStyle(fontSize: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class MealRecordRow extends StatelessWidget {
  final String mealType;
  final String count;
  MealRecordRow({required this.mealType, required this.count});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(mealType, style: TextStyle(fontSize: 16)),
        Text(count, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

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

class MealCard extends StatelessWidget {
  final String mealType;
  final int count;
  MealCard({required this.mealType, required this.count});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        title: Text(mealType, style: TextStyle(fontSize: 18)),
        trailing: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(count.toString(), style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class MealCard1 extends StatelessWidget {
  final String meal;
  final int count;
  final Color color;
  MealCard1({required this.meal, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              meal,
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class MealBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আজকের মিল বোর্ড: Friday, Jan 3rd',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Table(
                  border: TableBorder.all(),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('No./Name',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('BreakFast',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Launch',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Dinner',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('1#F Foysal',
                              style: TextStyle(color: Colors.blue)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              Text('1', style: TextStyle(color: Colors.green)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              Text('0', style: TextStyle(color: Colors.yellow)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('0', style: TextStyle(color: Colors.red)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('1'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'January ~ Bazar List:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SchedulePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.add, size: 50, color: Colors.blue),
        ),
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
  ScheduleEntry(
      {required this.date,
      required this.morning,
      required this.afternoon,
      required this.night});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            date,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TimeSlot(label: 'সকাল', value: morning, color: Colors.lightBlue),
              TimeSlot(
                  label: 'দুপুর', value: afternoon, color: Colors.pinkAccent),
              TimeSlot(label: 'রাত', value: night, color: Colors.teal),
            ],
          ),
        ],
      ),
    );
  }
}

class TimeSlot extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  TimeSlot({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: color),
        ),
        SizedBox(height: 5),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
        title: Text('January ~ Bazar List'),
      ),
      body: ListView.builder(
        itemCount: bazarList.length,
        itemBuilder: (context, index) {
          final item = bazarList[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/profile.png'),
              ),
              title: Text(item['name']!),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['from']!),
                  Text(item['to']!),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.lock),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FinancialSummaryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: [
        DataColumn(label: Text('ধরনঃ')),
        DataColumn(label: Text('টাকাঃ')),
      ],
      rows: [
        DataRow(cells: [
          DataCell(Text('#মোট মিলঃ')),
          DataCell(Text('1')),
        ]),
        DataRow(cells: [
          DataCell(Text('#মিল রেইটঃ')),
          DataCell(Text('0.00')),
        ]),
        DataRow(cells: [
          DataCell(Text('#মিল টাকারঃ')),
          DataCell(Text('0.00')),
        ]),
        DataRow(cells: [
          DataCell(Text('#অন্যায়ঃ')),
          DataCell(Text('698')),
        ]),
        DataRow(cells: [
          DataCell(Text('মোট টাকারঃ')),
          DataCell(Text('698')),
        ]),
        DataRow(cells: [
          DataCell(Text('বাজার খরচঃ')),
          DataCell(Text('0')),
        ]),
        DataRow(cells: [
          DataCell(Text('#পেইডঃ')),
          DataCell(Text('0')),
        ]),
      ],
    );
  }
}
