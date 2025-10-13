import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:black_box/model/mess/mess_main.dart';
import 'package:black_box/model/mess/mess_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../../model/user/user.dart';
import '../../../modules/widget/mess_drawer.dart';
import '../../../preference/logout.dart';
import '../../../routes/routes.dart';
import '../home_navigation/flip_card_dashboard.dart';

class MessDashboardPage extends StatefulWidget {
  const MessDashboardPage({super.key});

  @override
  State<MessDashboardPage> createState() => _MealCounterPageState();
}

class _MealCounterPageState extends State<MessDashboardPage> {
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  int _selectedIndex = 0;

  User? _user, _user_data;
  MessUser? messUser, messUser_data;
  MessMain? messMain;
  File? _selectedImage;
  bool isLoading = false;
  String? messUserType;

  @override
  void initState() {
    super.initState();

    _initializeData();
  }

  Future<void> _initializeData() async {
    await checkLoggedInOrNot();
    await _loadUserData();
  }

  Future<void> checkLoggedInOrNot() async {
    bool isLoggedIn = await Logout().isMessLoggedIn();
    String? muser_type = await Logout().getMessUserType();

    if (!isLoggedIn) {
      context.goNamed(Routes.homePage);
    } else {
      // User is not logged in, stay on the sign-in screen
      setState(() => isLoading = false);

      if (muser_type != null) messUserType = muser_type;
      if (muser_type == "member") {
        context.goNamed(Routes.messMember);
      } else if (muser_type == "employee") {
        context.goNamed(Routes.messEmployee);
      } else {}
    }
  }

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');
    MessUser? muser = await logout.getMessUserDetails(key: 'mess_user_data');

    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? muserMap =
        await logout.getMessUser(key: 'mess_user_logged_in');
    Map<String, dynamic>? messMap = await logout.getMess(key: 'mess_data');

    if (userMap != null) {
      User user_data = User.fromMap(userMap);
      setState(() {
        _user_data = user_data;
        _user = user;
      });
    } else {
      print("User map is null");
    }

    if (muserMap != null) {
      MessUser muser_data = MessUser.fromMap(muserMap);
      setState(() {
        messUser_data = muser_data;
        messUser = muser;
      });
    } else {
      print("Mess User map is null");
    }

    if (messMap != null) {
      MessMain messData = MessMain.fromMap(messMap);
      setState(() {
        messMain = messData;
        print(messData.messId);
      });
    } else {
      print("Mess data is null");
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_logged_in');
    String? imagePath = prefs.getString('profile_picture-${_user?.uniqueid!}');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        //set userData

        if (imagePath != null) {
          _selectedImage = File(imagePath);
        }
      });
    }
  }

  Future<void> getUserMessData() async {}

  Future<void> getMessData() async {}

  final List<DashboardItem> _dashboardItems = [
    DashboardItem(
      title: 'Meal Counter',
      icon: MdiIcons.food,
      color: Colors.orange,
      subtitle: 'Track daily meals',
    ),
    DashboardItem(
      title: 'Bazar List',
      icon: MdiIcons.cart,
      color: Colors.green,
      subtitle: 'Manage shopping',
    ),
    DashboardItem(
      title: 'Members',
      icon: MdiIcons.accountGroup,
      color: Colors.blue,
      subtitle: 'View all members',
    ),
    DashboardItem(
      title: 'Reports',
      icon: MdiIcons.chartBar,
      color: Colors.purple,
      subtitle: 'View monthly reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d').format(now);
    final banglaDate = DateFormat('EEEE, d MMMM', 'bn').format(now);

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.indigo.shade800),
          onPressed: () => Navigator.pop(context),
        ),
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
                    size: 16, color: Colors.indigo.shade800),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.indigo.shade800,
                  highlightColor: Colors.indigo.shade400,
                  child: Marquee(
                    text:
                        "Secondhome ${messUserType} - ${_user?.uname} - ${messUser?.email} - ${messUser?.phone} - Developed By Farhad Foysal",
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
        actions: [
          Builder(
            builder: (context) => Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.indigo.shade100,
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.menu_rounded, color: Colors.indigo.shade800),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.96),
                Colors.white.withOpacity(0.96),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      drawer: MessDrawer(),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Summary Card
            // _buildBalanceSummaryCard(),
            BalanceFlipCard(messUser!, messMain!),

            // Today's Meal Section
            _buildTodaysMealSection(formattedDate, banglaDate),

            // Dashboard Grid
            // _buildDashboardGrid(),
            FlipCardDashboard(),

            // Monthly Summary
            _buildMonthlySummary(),

            // Recent Transactions
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Honeycomb Menu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: _dashboardItems.length,
              itemBuilder: (context, index) {
                return Transform.translate(
                  offset: index.isEven ? const Offset(0, 20) : Offset.zero,
                  child: _buildHexItem(_dashboardItems[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexItem(DashboardItem item) {
    return ClipPath(
      clipper: HexagonClipper(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withOpacity(0.2),
                  item.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: item.color,
                ),
                const SizedBox(height: 4),
                Text(
                  item.title.split(' ').first,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysMealSection(String formattedDate, String banglaDate) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.pink.shade200, Colors.pink.shade100],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade800,
                      ),
                    ),
                    Text(
                      banglaDate,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Bengali Meal Cards
                _buildMealCard(
                  mealType: 'সকালের খাবার',
                  count: 1,
                  icon: Icons.wb_sunny,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(height: 12),
                _buildMealCard(
                  mealType: 'দুপুরের খাবার',
                  count: 0,
                  icon: Icons.sunny,
                  color: Colors.amber.shade300,
                ),
                const SizedBox(height: 12),
                _buildMealCard(
                  mealType: 'রাতের খাবার',
                  count: 0,
                  icon: Icons.nightlight_round,
                  color: Colors.indigo.shade300,
                ),
                const SizedBox(height: 16),

                // English Meal Cards Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildCompactMealCard(
                        meal: 'BreakFast',
                        count: 1,
                        color: Colors.lightBlueAccent.withOpacity(0.2),
                        textColor: Colors.lightBlueAccent.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactMealCard(
                        meal: 'Lunch',
                        count: 0,
                        color: Colors.pinkAccent.withOpacity(0.2),
                        textColor: Colors.pinkAccent.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactMealCard(
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
        ],
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 4),
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
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
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
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildTransactionItem(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(int index) {
    final transactions = [
      {
        'title': 'Meal Payment',
        'date': 'Today',
        'amount': '৳ 150.00',
        'isPositive': true
      },
      {
        'title': 'Bazar Cost',
        'date': 'Yesterday',
        'amount': '৳ 200.00',
        'isPositive': false
      },
      {
        'title': 'Deposit',
        'date': '2 days ago',
        'amount': '৳ 500.00',
        'isPositive': true
      },
    ];

    final transaction = transactions[index];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaction['isPositive'] as bool
                ? Colors.green.shade50
                : Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction['isPositive'] as bool
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color:
                transaction['isPositive'] as bool ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction['title'] as String),
        subtitle: Text(transaction['date'] as String),
        trailing: Text(
          transaction['amount'] as String,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                transaction['isPositive'] as bool ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard({
    required String mealType,
    required int count,
    required IconData icon,
    required Color color,
  }) {
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                mealType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      count > 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMealCard({
    required String meal,
    required int count,
    required Color color,
    required Color textColor,
  }) {
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
        padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 8),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
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

  TableRow _buildTableRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isTotal = false,
    bool isDue = false,
  }) {
    final textColor = isDue
        ? Colors.red.shade700
        : isTotal
            ? Colors.green.shade700
            : isHighlighted
                ? Colors.orange.shade700
                : Colors.grey.shade800;

    final bgColor = isTotal
        ? Colors.green.shade50
        : isDue
            ? Colors.red.shade50
            : isHighlighted
                ? Colors.orange.shade50
                : Colors.transparent;

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
                  ? FontWeight.bold
                  : FontWeight.normal,
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
              fontWeight:
                  isTotal || isDue ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ],
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

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
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
    });
  }

  // Widget _buildDashboardGrid() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.only(left: 4),
  //           child: Align(
  //             alignment: Alignment.centerLeft,
  //             child: Text(
  //               'Shortcuts',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.black45,
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 5,
  //           mainAxisSpacing: 8,
  //           crossAxisSpacing: 8,
  //           childAspectRatio: 1.0,
  //           children: _dashboardItems.map((item) => _buildNeumorphicItem(item)).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildNeumorphicItem(DashboardItem item) {
  //   return GestureDetector(
  //     onTap: () {},
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.grey.shade100,
  //         borderRadius: BorderRadius.circular(12),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.white,
  //             offset: const Offset(-3, -3),
  //             blurRadius: 3,
  //           ),
  //           BoxShadow(
  //             color: Colors.grey.shade400,
  //             offset: const Offset(3, 3),
  //             blurRadius: 3,
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             width: 28,
  //             height: 28,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: item.color.withOpacity(0.1),
  //             ),
  //             child: Icon(
  //               item.icon,
  //               size: 16,
  //               color: item.color,
  //             ),
  //           ),
  //           const SizedBox(height: 6),
  //           Text(
  //             item.title.substring(0, 3),
  //             style: TextStyle(
  //               fontSize: 10,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.black87,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDashboardGrid() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.only(left: 4),
  //           child: Align(
  //             alignment: Alignment.centerLeft,
  //             child: Text(
  //               'Quick Menu',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.black54,
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         Wrap(
  //           spacing: 12,
  //           runSpacing: 12,
  //           children: _dashboardItems.map((item) => _buildBubbleItem(item)).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildBubbleItem(DashboardItem item) {
  //   return Tooltip(
  //     message: item.subtitle,
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(24),
  //         onTap: () {},
  //         child: Container(
  //           width: 72,
  //           height: 72,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             gradient: RadialGradient(
  //               colors: [
  //                 item.color.withOpacity(0.15),
  //                 item.color.withOpacity(0.05),
  //               ],
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: item.color.withOpacity(0.1),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(
  //                 item.icon,
  //                 size: 24,
  //                 color: item.color,
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 item.title.split(' ').first,
  //                 style: TextStyle(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDashboardGrid() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 8),
  //           child: Align(
  //             alignment: Alignment.centerLeft,
  //             child: Text(
  //               'Quick Actions',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w700,
  //                 color: Colors.black87,
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 4, // More items per row
  //           mainAxisSpacing: 12,
  //           crossAxisSpacing: 12,
  //           childAspectRatio: 0.8, // More compact aspect ratio
  //           children: _dashboardItems.map((item) => _buildGlassItem(item)).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildGlassItem(DashboardItem item) {
  //   return MouseRegion(
  //     cursor: SystemMouseCursors.click,
  //     child: TweenAnimationBuilder(
  //       tween: Tween(begin: 0.95, end: 1.0),
  //       duration: const Duration(milliseconds: 200),
  //       builder: (context, value, child) {
  //         return Transform.scale(
  //           scale: value,
  //           child: child,
  //         );
  //       },
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(16),
  //           onTap: () {},
  //           splashColor: item.color.withOpacity(0.2),
  //           child: Container(
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(16),
  //               border: Border.all(
  //                 color: Colors.white.withOpacity(0.3),
  //                 width: 1.5,
  //               ),
  //               gradient: LinearGradient(
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //                 colors: [
  //                   Colors.white.withOpacity(0.15),
  //                   Colors.white.withOpacity(0.05),
  //                 ],
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 10,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Container(
  //                   width: 36,
  //                   height: 36,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     gradient: RadialGradient(
  //                       colors: [
  //                         item.color.withOpacity(0.2),
  //                         item.color.withOpacity(0.1),
  //                       ],
  //                     ),
  //                   ),
  //                   child: Icon(
  //                     item.icon,
  //                     size: 20,
  //                     color: item.color,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   item.title,
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDashboardGrid() {
  //   return Padding(
  //     padding: const EdgeInsets.all(20.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 8.0),
  //           child: RichText(
  //             text: TextSpan(
  //               children: [
  //                 TextSpan(
  //                   text: 'Quick ',
  //                   style: TextStyle(
  //                     fontSize: 22,
  //                     fontWeight: FontWeight.w800,
  //                     color: Colors.black87,
  //                     letterSpacing: 0.8,
  //                   ),
  //                 ),
  //                 TextSpan(
  //                   text: 'Access',
  //                   style: TextStyle(
  //                     fontSize: 22,
  //                     fontWeight: FontWeight.w800,
  //                     color: Colors.teal.shade600,
  //                     letterSpacing: 0.8,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 2,
  //           mainAxisSpacing: 24,
  //           crossAxisSpacing: 24,
  //           childAspectRatio: 0.85,
  //           children: _dashboardItems.map((item) => _buildDashboardItem(item)).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildDashboardItem(DashboardItem item) {
  //   final random = Random(item.title.hashCode);
  //   final bgColor = Color.lerp(
  //     item.color.withOpacity(0.05),
  //     item.color.withOpacity(0.15),
  //     random.nextDouble(),
  //   )!;
  //
  //   return MouseRegion(
  //     cursor: SystemMouseCursors.click,
  //     child: TweenAnimationBuilder<double>(
  //       duration: const Duration(milliseconds: 300),
  //       tween: Tween(begin: 0.97, end: 1.0),
  //       builder: (context, scale, child) {
  //         return Transform.scale(
  //           scale: scale,
  //           child: child,
  //         );
  //       },
  //       child: Card(
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(24),
  //         ),
  //         margin: EdgeInsets.zero,
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(24),
  //           onTap: () {},
  //           splashColor: item.color.withOpacity(0.2),
  //           highlightColor: item.color.withOpacity(0.1),
  //           child: Container(
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(24),
  //               gradient: LinearGradient(
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //                 colors: [
  //                   bgColor,
  //                   bgColor.withOpacity(0.7),
  //                 ],
  //               ),
  //               border: Border.all(
  //                 color: item.color.withOpacity(0.15),
  //                 width: 1.0,
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: item.color.withOpacity(0.05),
  //                   blurRadius: 12,
  //                   offset: const Offset(0, 6),
  //                 ),
  //               ],
  //             ),
  //             child: Stack(
  //               children: [
  //                 // Decorative elements
  //                 Positioned(
  //                   top: -20,
  //                   right: -20,
  //                   child: Container(
  //                     width: 80,
  //                     height: 80,
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       gradient: RadialGradient(
  //                         colors: [
  //                           item.color.withOpacity(0.08),
  //                           Colors.transparent,
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 Positioned(
  //                   bottom: 10,
  //                   left: 10,
  //                   child: Transform.rotate(
  //                     angle: -0.2,
  //                     child: Container(
  //                       width: 60,
  //                       height: 60,
  //                       decoration: BoxDecoration(
  //                         shape: BoxShape.rectangle,
  //                         borderRadius: BorderRadius.circular(12),
  //                         color: item.color.withOpacity(0.05),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 // Content
  //                 Padding(
  //                   padding: const EdgeInsets.all(20.0),
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Container(
  //                         width: 54,
  //                         height: 54,
  //                         decoration: BoxDecoration(
  //                           color: item.color.withOpacity(0.15),
  //                           borderRadius: BorderRadius.circular(14),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: item.color.withOpacity(0.1),
  //                               blurRadius: 8,
  //                               offset: const Offset(0, 4),
  //                             ),
  //                           ],
  //                         ),
  //                         child: Center(
  //                           child: Icon(
  //                             item.icon,
  //                             size: 28,
  //                             color: item.color,
  //                           ),
  //                         ),
  //                       ),
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             item.title,
  //                             style: TextStyle(
  //                               fontSize: 17,
  //                               fontWeight: FontWeight.w700,
  //                               color: Colors.black87,
  //                               height: 1.2,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 4),
  //                           Text(
  //                             item.subtitle,
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               color: Colors.grey.shade600,
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Align(
  //                         alignment: Alignment.centerRight,
  //                         child: Container(
  //                           width: 32,
  //                           height: 32,
  //                           decoration: BoxDecoration(
  //                             color: item.color.withOpacity(0.15),
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: Icon(
  //                             Icons.arrow_forward_rounded,
  //                             size: 16,
  //                             color: item.color,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDashboardGrid() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.only(left: 8.0),
  //           child: Text(
  //             'Quick Access',
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.w800,
  //               color: Colors.black87,
  //               letterSpacing: 0.5,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 2,
  //           mainAxisSpacing: 20,
  //           crossAxisSpacing: 20,
  //           childAspectRatio: 0.9,
  //           children: _dashboardItems.map((item) => _buildDashboardItem(item)).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildDashboardItem(DashboardItem item) {
  //   return MouseRegion(
  //     cursor: SystemMouseCursors.click,
  //     child: TweenAnimationBuilder<double>(
  //       duration: const Duration(milliseconds: 300),
  //       tween: Tween(begin: 0.95, end: 1.0),
  //       builder: (context, scale, child) {
  //         return Transform.scale(
  //           scale: scale,
  //           child: child,
  //         );
  //       },
  //       child: Card(
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(20),
  //           onTap: () {},
  //           splashColor: item.color.withOpacity(0.2),
  //           highlightColor: item.color.withOpacity(0.1),
  //           child: Container(
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(20),
  //               border: Border.all(
  //                 color: item.color.withOpacity(0.3),
  //                 width: 1.5,
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: item.color.withOpacity(0.1),
  //                   blurRadius: 10,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Stack(
  //               children: [
  //                 Positioned(
  //                   top: -10,
  //                   right: -10,
  //                   child: Container(
  //                     width: 60,
  //                     height: 60,
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       color: item.color.withOpacity(0.1),
  //                     ),
  //                   ),
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Container(
  //                         width: 50,
  //                         height: 50,
  //                         decoration: BoxDecoration(
  //                           color: item.color.withOpacity(0.2),
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                         child: Icon(
  //                           item.icon,
  //                           size: 28,
  //                           color: item.color,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 16),
  //                       Text(
  //                         item.title,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w700,
  //                           color: Colors.black87,
  //                           height: 1.2,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         item.subtitle,
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey.shade600,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Align(
  //                         alignment: Alignment.centerRight,
  //                         child: Container(
  //                           padding: const EdgeInsets.symmetric(
  //                               horizontal: 8, vertical: 4),
  //                           decoration: BoxDecoration(
  //                             color: item.color.withOpacity(0.2),
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                           child: Icon(
  //                             Icons.arrow_forward_rounded,
  //                             size: 16,
  //                             color: item.color,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDashboardGrid() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Quick Access',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 2,
  //           mainAxisSpacing: 16,
  //           crossAxisSpacing: 16,
  //           childAspectRatio: 1.2,
  //           children: _dashboardItems.map((item) => _buildDashboardItem(item)).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildDashboardItem(DashboardItem item) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(15),
  //     ),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(15),
  //       onTap: () {},
  //       child: Container(
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(15),
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [
  //               item.color.withOpacity(0.1),
  //               item.color.withOpacity(0.05),
  //             ],
  //           ),
  //         ),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               item.icon,
  //               size: 36,
  //               color: item.color,
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               item.title,
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 color: item.color,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               item.subtitle,
  //               style: const TextStyle(
  //                 fontSize: 12,
  //                 color: Colors.grey,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBalanceSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Balance Summary
              Container(
                padding: const EdgeInsets.all(16),
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

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BalanceFlipCard extends StatefulWidget {
  final MessUser messUser;
  final MessMain messMain;
  BalanceFlipCard(this.messUser, this.messMain);

  @override
  _BalanceFlipCardState createState() => _BalanceFlipCardState();
}

class _BalanceFlipCardState extends State<BalanceFlipCard> {
  bool _showPersonalBalance = true;
  final Color _primaryColor = Color(0xFF00C6AB);
  final Color _secondaryColor = Color(0xFF0082A8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showPersonalBalance = !_showPersonalBalance;
        });
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, widget) {
              return Transform(
                transform: Matrix4.rotationY(rotateAnim.value),
                alignment: Alignment.center,
                child: widget,
              );
            },
          );
        },
        child: _showPersonalBalance
            ? _buildPersonalBalanceCard()
            : _buildMessStatsCard(),
      ),
    );
  }

  Widget _buildPersonalBalanceCard() {
    return Container(
      key: ValueKey<bool>(true),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
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
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Balance Summary
                Container(
                  padding: const EdgeInsets.all(16),
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
              ],
            ),
          ),
        ),
      ),
      // child: Padding(
      //   padding: const EdgeInsets.all(20.0),
      //   child: Column(
      //     children: [
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           Text(
      //             'আমার ব্যালেন্স',
      //             style: TextStyle(
      //               fontSize: 16,
      //               color: Colors.white.withOpacity(0.9),
      //             ),
      //           ),
      //           Text(
      //             'মোট মিল',
      //             style: TextStyle(
      //               fontSize: 16,
      //               color: Colors.white.withOpacity(0.9),
      //             ),
      //           ),
      //         ],
      //       ),
      //       SizedBox(height: 8),
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           Text(
      //             '৳ ২০.০০',
      //             style: TextStyle(
      //               fontSize: 28,
      //               fontWeight: FontWeight.bold,
      //               color: Colors.white,
      //             ),
      //           ),
      //           Text(
      //             '২.০০',
      //             style: TextStyle(
      //               fontSize: 28,
      //               fontWeight: FontWeight.bold,
      //               color: Colors.white,
      //             ),
      //           ),
      //         ],
      //       ),
      //       SizedBox(height: 20),
      //       Divider(color: Colors.white.withOpacity(0.3), height: 1),
      //       SizedBox(height: 20),
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           _buildStatItem(
      //             icon: Icons.arrow_downward,
      //             label: 'আমার আমানত',
      //             amount: '৳ ১৫০.০০',
      //             color: Colors.white,
      //           ),
      //           _buildStatItem(
      //             icon: Icons.arrow_upward,
      //             label: 'আমার খরচ',
      //             amount: '৳ ১৩০.০০',
      //             color: Colors.white,
      //           ),
      //         ],
      //       ),
      //       SizedBox(height: 10),
      //       Align(
      //         alignment: Alignment.centerRight,
      //         child: Text(
      //           'ট্যাপ করুন মেস স্ট্যাট দেখতে',
      //           style: TextStyle(
      //             fontSize: 10,
      //             color: Colors.white.withOpacity(0.7),
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

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

  Widget _buildMessStatsCard() {
    return Container(
      key: ValueKey<bool>(false),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
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
                  'মেস ব্যালেন্স',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'মোট সদস্য',
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
                  '৳ ৫,২০০.০০',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '৭ জন',
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
                  icon: Icons.restaurant,
                  label: 'মাসিক মিল',
                  amount: '১৮০ টি',
                  color: Colors.white,
                ),
                _buildStatItem(
                  icon: Icons.shopping_basket,
                  label: 'মাসিক বাজার',
                  amount: '৳ ১২,৫০০',
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  icon: Icons.arrow_downward,
                  label: 'মোট আমানত',
                  amount: '৳ ১৫,০০০',
                  color: Colors.white,
                ),
                _buildStatItem(
                  icon: Icons.arrow_upward,
                  label: 'মোট খরচ',
                  amount: '৳ ৯,৮০০',
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ট্যাপ করুন ব্যক্তিগত ব্যালেন্স দেখতে',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          amount,
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
