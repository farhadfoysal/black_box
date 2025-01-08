import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:black_box/db/local/database_manager.dart';
import 'package:black_box/screen_page/mess/mess_home_admin.dart';
import 'package:black_box/screen_page/mess/mess_home_employee.dart';
import 'package:black_box/screen_page/mess/mess_home_member.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../cores/cores.dart';
import '../../db/local/database_helper.dart';
import '../../model/mess/mess_main.dart';
import '../../model/mess/mess_user.dart';
import '../../model/school/school.dart';
import '../../model/school/teacher.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../routes/routes.dart';
import '../../utility/unique.dart';

class MessMainScreen extends StatefulWidget {
  @override
  State<MessMainScreen> createState() => _MessMainScreenState();
}

class _MessMainScreenState extends State<MessMainScreen> {
  // final _auth = FirebaseAuth.instance;
  final _databaseRef = FirebaseDatabase.instance.ref();

  final messName = TextEditingController();
  final messPhone = TextEditingController();
  final messAddress = TextEditingController();
  final messCode = TextEditingController();
  final messPassword = TextEditingController();

  bool isJoining = false; // Toggle between create and join forms
  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  MessUser? messUser, _mess_user_data;
  MessMain? messMain;
  String? sid;
  String? messId;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  late TabController _tabController;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeData();

  }

  void checkMessLoginStatus() async {
    bool isLoggedIn = await Logout().isMessLoggedIn();
    String? isUser = await Logout().getMessUserType();

    if (isLoggedIn) {
      if (isUser != null) {
        if (isUser == "admin") {
          context.push(Routes.messAdmin);
        } else if (isUser == "employee") {
          context.push(Routes.messEmployee);
        } else {

          context.push(Routes.messMember);

        }
      }
    } else {

      loginMessUser();

    }
  }

  Future<void> loginMessUser() async {
    if(await InternetConnectionChecker.instance.hasConnection){

      if(_user==null){
        print("null");
      }

      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('musers')
          .child(_user!.userid??"");

      final snapshot = await userRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
        MessUser user = MessUser.fromMap(userData);
        setState(() {
          messUser = user;
        });

        if (mounted) {
          if(user.userType=="member") {
            await Logout().setMessLoggedIn(true);
            await Logout().setMessUserType("member");
            await Logout().saveMessUser(user.toMap(), key: "mess_user_logged_in");
            await Logout().saveMessUserDetails(user, key: "mess_user_data");

            setState(() {
              // loading = false;
            });
            await getMessData(user);
            // context.goNamed(Routes.homePage);
            context.push(Routes.messMember);


          }else if(user.userType=="employee"){

            await Logout().setMessLoggedIn(true);
            await Logout().setMessUserType("employee");
            await Logout().saveMessUser(user.toMap(), key: "mess_user_logged_in");
            await Logout().saveMessUserDetails(user, key: "mess_user_data");

            setState(() {
              // loading = false;
            });
            await getMessData(user);
            context.push(Routes.messEmployee);
            // context.goNamed(Routes.homePage);

          }else{

            await Logout().setMessLoggedIn(true);
            await Logout().setMessUserType("admin");
            await Logout().saveMessUser(user.toMap(), key: "mess_user_logged_in");
            await Logout().saveMessUserDetails(user, key: "mess_user_data");
            await getMessData(user);

            setState(() {
              // loading = false;
            });

            context.push(Routes.messAdmin);
            // context.goNamed(Routes.homePage);

          }
        }
      } else {
        showSnackBarMsg(context, 'MessUser data not found!');
        setState(() {
          isJoining = false;
        });
      }


    }
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    await _loadMessUserData();
    checkMessLoginStatus();

  }

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');

    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? schoolMap =
    await logout.getSchool(key: 'school_data');

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

  Future<void> _loadMessUserData() async {
    Logout logout = Logout();
    MessUser? user = await logout.getMessUserDetails(key: 'mess_user_data');

    Map<String, dynamic>? MessUserMap =
    await logout.getMessUser(key: 'mess_user_logged_in');
    Map<String, dynamic>? messMap = await logout.getMess(key: 'mess_data');

    if (MessUserMap != null) {
      MessUser user_data = MessUser.fromMap(MessUserMap);
      setState(() {
        _mess_user_data = user_data;
      });
    } else {
      print("Mess User map is null");
    }

    if (messMap != null) {
      MessMain messData = MessMain.fromMap(messMap);
      setState(() {
        messUser = user;
        messMain = messData;
        messId = messMain?.messId;
        print(messData.messId);
      });
    } else {
      print("Mess data is null");
      setState(() {
        isJoining = true;
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (messMain == null) ...[
              Text(
                isJoining ? "Join Mess" : "Create New Mess",
                style: p21.bold,
              ),
              SizedBox(height: 20),
              if (!isJoining) ...[
                TextFormField(
                  controller: messName,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mess name ';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Mess Name",
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: messPhone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Phone",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: messAddress,
                  decoration: InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: messPassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveMess,
                  child: Text("Create Mess"),
                ),
              ] else ...[
                TextFormField(
                  controller: messCode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mess code ';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Mess Code",
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    joinMess();
                  },
                  child: Text("Join Mess"),
                ),
                SizedBox(height: 20), // Add spacing between the buttons
                ElevatedButton(
                  onPressed: () {
                    loginMessUser();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25), // Rounded edges
                    ),
                    elevation: 5, // Shadow effect
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login, size: 20), // Icon for Login
                      SizedBox(width: 10),
                      Text(
                        "Click to Login Messhome",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    isJoining = !isJoining; // Toggle between forms
                  });
                },
                child: Text(
                  isJoining
                      ? "Create a New Mess Instead"
                      : "Already have a Mess? Join with Code",
                  style: TextStyle(color: context.themeD.primaryColor),
                ),
              ),
            ] else ...[
              // If messMain is not null
              Text(
                "You are already part of a Mess",
                style: p21.bold,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  checkMessLoginStatus();
                  // Navigate to Mess Home
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => MessHomeScreen(), // Replace with your MessHomeScreen
                  //   ),
                  // );
                },
                child: Text("Go to Mess Home"),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Future<void> saveMess() async {
    var uuid = Uuid();
    String uniqueId = Unique().generateUniqueID();

    int ranId = Random().nextInt(1000000000) + DateTime.now().millisecondsSinceEpoch;
    String referr = utf8.decode([Random().nextInt(256)]).toUpperCase();
    String numberr = '$ranId$referr';

    final newMess = MessMain(
      // messId: uuid.v4(),
      messId: numberr,
      mId: uniqueId,
      messName: messName.text,
      adminPhone: messPhone.text,
      messPass: messPassword.text,
      messAddress: messAddress.text,
      messAdminId: _user?.uniqueid,
      startDate: DateTime.now(),
      mealUpdateStatus: "1",
      uPerm: "0",
    );
    setState(() {
      messMain = newMess;
      messId = newMess.messId;
    });

    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref("mess").child(newMess.messId!);

      try {
        await dbRef.set(newMess.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mess saved successfully!')),
        );

        if (mounted) {
          setState(() {});
        }
        await setUserMessOnline(_user ?? _user_data,newMess,"admin");
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const AdminLogin(),
        //   ),
        // );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Mess: $e')),
        );
      }
    }else{
      final result = await DatabaseManager().insertMess(newMess);
      if (result > 0) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mess saved successfully!')),
        );

        if (mounted) {
          setState(() {});
        }

        // context.push(Routes.messAdmin);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Mess')),
        );
      }
    }
  }

  Future<void>  setUserMessOnline(User? user, MessMain newMess, String member)async {
    DatabaseReference usersRef = _databaseRef.child("musers");
    DatabaseEvent event = await usersRef.orderByChild("phone").equalTo(user?.phone).once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      showSnackBarMsg(context, 'Phone number is already registered.');
      return;
    }
    String phoneId = "${user?.phone ?? ''}${generateRefer()}";
    MessUser newMessUser = MessUser(
      uniqueId: user?.uniqueid,
      userId: user?.userid,
      phone: user?.phone,
      email: user?.email,
      userType: member,
      messId: newMess.messId,
      phonePass: phoneId,
    );

    await _databaseRef.child("musers").child(user!.userid!).set(newMessUser.toMap());

    print("User successfully signed up and saved to database");

    await saveMessUserOffline(newMessUser);

  }

  Future<void> saveMessUserOffline(MessUser messUser) async {

    MessUser? existingUser = await DatabaseManager().getMessUserByPhone(messUser!.phone!);

    if (existingUser != null) {

      if (mounted) {
        showSnackBarMsg(context, 'User already registered');
      }
      if (mounted) {
        setState(() {});
      }
      return;
    }


    int result = await DatabaseManager().insertMessUser(messUser);

    if (mounted) {
      setState(() {});
    }

    if (result > 0) {

    } else {
      if (mounted) {
        showSnackBarMsg(context, 'Registration Failed');
      }
    }

  }

  Future<void> getMessData(MessUser messUser) async {
    if (messUser.messId == null) {
      print("MessID is null, unable to fetch school data.");
      return;
    }

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("mess").child(messUser.messId!);

    try {
      final DataSnapshot snapshot = await dbRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic> schoolData = Map<String, dynamic>.from(snapshot.value as Map);
        MessMain mess = MessMain.fromMap(schoolData);

        setState(() {
          messMain = mess;
        });

        await Logout().saveMess(mess.toMap(),key: "mess_data");

        print("mess data fetched successfully: ${mess.messName}");

      } else {
        print("mess with messID  does not exist.");
      }
    } catch (e) {
      print("Error fetching mess data: $e");
    }
  }

  void joinMess(){
    String mess = messCode.text.toString();
  }

  String generateRefer() {

    int randomByte = Random().nextInt(256);
    String refer = randomByte.toRadixString(16).padLeft(2, '0').toUpperCase();

    return refer;
  }
}
