import 'dart:convert';
import 'dart:io';

import 'package:black_box/screen_page/mess/home_navigation/bazar/bazar_expense.dart';
import 'package:black_box/screen_page/mess/home_navigation/payment/monthly_calculation.dart';
import 'package:black_box/screen_page/mess/home_navigation/payment/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/mess/bazar_list.dart';
import '../../../model/mess/mess_main.dart';
import '../../../model/mess/mess_user.dart';
import '../../../model/school/school.dart';
import '../../../model/school/teacher.dart';
import '../../../model/user/user.dart';
import '../../../preference/logout.dart';
import '../../../routes/app_router.dart';
import 'bazar/barzar_expense_list_page.dart';
import 'bazar/bazar_schedule_list_page.dart';

class BazarListPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return BazarListPageState();
  }

}

class BazarListPageState extends State<BazarListPage> with SingleTickerProviderStateMixin{

  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  String? sid;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  late TabController _tabController;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;


  // Create dummy data
  final MessMain dummyMessInfo = MessMain(
    id: 1,
    messId: 'MESS001',
    messName: 'Delicious Food Mess',
    messAddress: '123 Food Street, Flutter City',
    currentMonth: 'August 2025',
  );

  final List<MessUser> dummyUsers = [
    MessUser(
      id: 1,
      userId: 'John Doe',
      phone: '+8801712345678',
      email: 'john.doe@example.com',
      bazarStart: DateTime(2025, 8, 1),
      bazarEnd: DateTime(2025, 8, 3),
      img: 'https://randomuser.me/api/portraits/men/1.jpg',
    ),
    MessUser(
      id: 2,
      userId: 'Jane Smith',
      phone: '+8801812345678',
      email: 'jane.smith@example.com',
      bazarStart: DateTime(2025, 8, 4),
      bazarEnd: DateTime(2025, 8, 6),
      img: 'https://randomuser.me/api/portraits/women/1.jpg',
    ),
    MessUser(
      id: 3,
      userId: 'Robert Johnson',
      phone: '+8801912345678',
      email: 'robert.j@example.com',
      bazarStart: DateTime(2025, 8, 7),
      bazarEnd: DateTime(2025, 8, 9),
      img: 'https://randomuser.me/api/portraits/men/2.jpg',
    ),
    MessUser(
      id: 4,
      userId: 'Emily Davis',
      phone: '+8801612345678',
      email: 'emily.d@example.com',
      bazarStart: DateTime(2025, 8, 10),
      bazarEnd: DateTime(2025, 8, 12),
      img: 'https://randomuser.me/api/portraits/women/2.jpg',
    ),
    MessUser(
      id: 5,
      userId: 'Michael Wilson',
      phone: '+8801512345678',
      email: 'michael.w@example.com',
      img: 'https://randomuser.me/api/portraits/men/3.jpg',
    ),
    MessUser(
      id: 6,
      userId: 'Sarah Johnson',
      phone: '+8801712345679',
      email: 'sarah.j@example.com',
      bazarStart: DateTime(2025, 8, 13),
      bazarEnd: DateTime(2025, 8, 15),
      img: 'https://randomuser.me/api/portraits/women/3.jpg',
    ),
    MessUser(
      id: 7,
      userId: 'David Miller',
      phone: '+8801812345679',
      email: 'david.m@example.com',
      bazarStart: DateTime(2025, 8, 16),
      bazarEnd: DateTime(2025, 8, 18),
      img: 'https://randomuser.me/api/portraits/men/4.jpg',
    ),
  ];

  final List<BazarList> dummyBazarLists = [
    // August 2025 bazar lists
    BazarList(
      listId: '1',
      uniqueId: 'BZR001',
      messId: 'MESS001',
      phone: '+8801712345678', // John Doe
      listDetails: 'Rice, Oil, Spices, Vegetables',
      amount: '3250.75',
      dateTime: DateTime(2025, 8, 1),
      adminNotify: '1',
    ),
    BazarList(
      listId: '2',
      uniqueId: 'BZR002',
      messId: 'MESS001',
      phone: '+8801712345678', // John Doe
      listDetails: 'Chicken, Fish, Eggs',
      amount: '2850.00',
      dateTime: DateTime(2025, 8, 2),
      adminNotify: '1',
    ),
    BazarList(
      listId: '3',
      uniqueId: 'BZR003',
      messId: 'MESS001',
      phone: '+8801812345678', // Jane Smith
      listDetails: 'Fruits, Milk, Bread',
      amount: '1750.50',
      dateTime: DateTime(2025, 8, 4),
      adminNotify: '0',
    ),
    BazarList(
      listId: '4',
      uniqueId: 'BZR004',
      messId: 'MESS001',
      phone: '+8801812345678', // Jane Smith
      listDetails: 'Beef, Lentils, Onions',
      amount: '3200.00',
      dateTime: DateTime(2025, 8, 5),
      adminNotify: '0',
    ),
    BazarList(
      listId: '5',
      uniqueId: 'BZR005',
      messId: 'MESS001',
      phone: '+8801912345678', // Robert Johnson
      listDetails: 'Vegetables, Spices, Oil',
      amount: '2450.25',
      dateTime: DateTime(2025, 8, 7),
      adminNotify: '1',
    ),
    BazarList(
      listId: '6',
      uniqueId: 'BZR006',
      messId: 'MESS001',
      phone: '+8801912345678', // Robert Johnson
      listDetails: 'Fish, Chicken, Eggs',
      amount: '2950.00',
      dateTime: DateTime(2025, 8, 8),
      adminNotify: '1',
    ),
    BazarList(
      listId: '7',
      uniqueId: 'BZR007',
      messId: 'MESS001',
      phone: '+8801612345678', // Emily Davis
      listDetails: 'Rice, Flour, Sugar',
      amount: '2100.75',
      dateTime: DateTime(2025, 8, 10),
      adminNotify: '0',
    ),
    BazarList(
      listId: '8',
      uniqueId: 'BZR008',
      messId: 'MESS001',
      phone: '+8801612345678', // Emily Davis
      listDetails: 'Vegetables, Fruits, Milk',
      amount: '1850.50',
      dateTime: DateTime(2025, 8, 11),
      adminNotify: '0',
    ),
    BazarList(
      listId: '9',
      uniqueId: 'BZR009',
      messId: 'MESS001',
      phone: '+8801712345679', // Sarah Johnson
      listDetails: 'Chicken, Fish, Spices',
      amount: '2750.00',
      dateTime: DateTime(2025, 8, 13),
      adminNotify: '1',
    ),
    BazarList(
      listId: '10',
      uniqueId: 'BZR010',
      messId: 'MESS001',
      phone: '+8801712345679', // Sarah Johnson
      listDetails: 'Rice, Oil, Vegetables',
      amount: '2250.25',
      dateTime: DateTime(2025, 8, 14),
      adminNotify: '1',
    ),

    // Previous month's data for testing
    BazarList(
      listId: '11',
      uniqueId: 'BZR011',
      messId: 'MESS001',
      phone: '+8801812345678', // Jane Smith
      listDetails: 'July Month-End Shopping',
      amount: '4200.00',
      dateTime: DateTime(2025, 7, 28),
      adminNotify: '0',
    ),
    BazarList(
      listId: '12',
      uniqueId: 'BZR012',
      messId: 'MESS001',
      phone: '+8801912345678', // Robert Johnson
      listDetails: 'July Groceries',
      amount: '3800.50',
      dateTime: DateTime(2025, 7, 21),
      adminNotify: '1',
    ),
  ];
  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeData();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();

  }

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');


    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? schoolMap = await logout.getSchool(key: 'school_data');


    if (userMap != null) {
      User user_data = User.fromMap(userMap);
      setState(() {
        _user_data = user_data;
        _user = user_data;

      });
    } else {
      print("User map is null");
    }

    if (schoolMap != null) {
      School schoolData = School.fromMap(schoolMap);
      setState(() {
        _user = user;
        school = schoolData;
        sid = school?.sId;
        print(schoolData.sId);
      });
    } else {
      print("School data is null");
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_logged_in');
    String? imagePath = prefs.getString('profile_picture-${_user?.uniqueid!}');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        userName = userData['uname'];
        userPhone = userData['phone'];
        userEmail = userData['email'];
        if (imagePath != null) {
          _selectedImage = File(imagePath);
        }
      });
    }
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserData = prefs.getString('user_logged_in');

    if (savedUserData != null) {
      Map<String, dynamic> userData = jsonDecode(savedUserData);
      setState(() {
        _userName = userData['uname'] ?? 'Tasnim';
      });
    }
  }

  Future<void> _loadUser() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');
    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    User user_data = User.fromMap(userMap!);
    setState(() {
      _user = user;
      _user_data = user_data;
    });
  }

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _onSwipe1(int index) {
    setState(() {
      _currentIndex1 = index;
    });
  }

  void _onSwipe2(int index) {
    setState(() {
      _currentIndex2 = index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> signOut() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully signed out')),
    );
    await AppRouter.logoutUser(context);
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          PreferredSize(
            preferredSize: const Size.fromHeight(30.0),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.black,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black.withOpacity(0.6),
                      tabs: const [
                        Tab(text: 'Bazar'),
                        Tab(text: 'Bazar List'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // BazarList(),
                BazarScheduleListPage(
                  users: dummyUsers,
                  messInfo: dummyMessInfo,
                ),
                // BazarExpense(),
                BazarExpenseListPage(
                  users: dummyUsers,
                  bazarLists: dummyBazarLists,
                  messInfo: dummyMessInfo,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}