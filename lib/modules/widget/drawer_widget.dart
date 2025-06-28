import 'dart:async';
import 'dart:io';

import 'package:black_box/meter/ui/view/auth/login_screen.dart';
import 'package:black_box/quiz/quiz_exam_screen.dart';
import 'package:black_box/screen_page/signin/sign_in_or_register.dart';
import 'package:black_box/routine/routine_screen.dart';
import 'package:black_box/screen_page/mess/mess_main_screen.dart';
import 'package:black_box/screen_page/tutor/tutor_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../cores/cores.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../routes/app_router.dart';
import '../../screen_page/routine/routine_page.dart';
import '../../task/task_main.dart';
import '../../web/internet_connectivity.dart';


class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  String? userName;
  String? userPhone;
  String? userEmail;
  File? _selectedImage;
  bool _showSaveButton = false;
  User? _user, _user_data;
  final _formKey = GlobalKey<FormState>();
  String? sid;
  School? school;

  bool isConnected = false;
  late StreamSubscription subscription;
  final internetChecker = InternetConnectivity();
  StreamSubscription<InternetConnectionStatus>? connectionSubscription;

  bool loading = false;

  @override
  void dispose() {
    stopListening();
    connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _loadUserData();
  }

  Future<void> _initializeApp() async {

    startListening();
    checkConnection();
    subscription = internetChecker.checkConnectionContinuously((status) {

      isConnected = status;

    });
  }
  void checkConnection() async {
    bool result = await internetChecker.hasInternetConnection();
    setState(() {
      isConnected = result;
    });
  }

  StreamSubscription<InternetConnectionStatus> checkConnectionContinuously() {
    return InternetConnectionChecker.instance.onStatusChange.listen((InternetConnectionStatus status) {
      if (status == InternetConnectionStatus.connected) {
        isConnected = true;
        showConnectivitySnackBar(isConnected);
        print('Connected to the internet drawer');

      } else {
        isConnected = false;
        showConnectivitySnackBar(isConnected);
        print('Disconnected from the internet drawer');
        // _loadSchoolData();
      }
    });
  }

  void showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }


  void startListening() {
    connectionSubscription = checkConnectionContinuously();
  }

  void stopListening() {
    connectionSubscription?.cancel();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _showSaveButton = true;
        _saveProfilePicture(pickedFile.path);  // Save the image path
      });
    }
  }

  Future<void> _saveProfilePicture(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture-${_user?.uniqueid!}', path);
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

  Widget _buildDrawerTile(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.lightPrimaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(
                        Icons.person_pin_circle_sharp,
                        size: 60,
                        color: Colors.white,
                      )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  userName ?? 'T A S N I M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        userPhone ?? '+008 1800-445566',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(Icons.email_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        userEmail ?? 'r@gmail.com',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.person_2),
          //   title: const Text('Tuition Tracker'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(context, MaterialPageRoute(builder: (context) => TutorMainScreen()));
          //   },
          // ),
          _buildDrawerTile(Icons.history_edu, 'Tuition Tracker', TutorMainScreen()),
          _buildDrawerTile(Icons.quiz, 'QUIZ | EXAM', QuizExamScreen()),
          _buildDrawerTile(Icons.dining, 'MessHome', MessMainScreen()),
          _buildDrawerTile(Icons.task, 'Task', TaskMain()),
          _buildDrawerTile(Icons.schedule_send_outlined, 'Routine | Schedule', RoutinePage()),
          _buildDrawerTile(Icons.electric_meter, 'Prepaid', LoginScreen()),
          // _buildDrawerTile(Icons.schedule_send_outlined, 'East Delta Routine', RoutineScreen()),

          // _buildDrawerTile(Icons.palette, 'P R O F I L E', const EditProfileScreen()),
          // _buildDrawerTile(Icons.bus_alert_outlined, 'B U S ', const BusSchedule()),
          // _buildDrawerTile(Icons.bloodtype, 'C L A S S  M A N A G E R', ClassManagerPage()),
          // _buildDrawerTile(Icons.note, 'N O T E S & T A S K S', NotesScreen()),
          // _buildDrawerTile(Icons.calendar_month_outlined, 'ACADEMIC - C A L E N D A R', AcademicCalender()),
          // _buildDrawerTile(Icons.settings, 'S E T T I N G S', const SettingScreen()),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('L O G O U T'),
            // onTap: () async {
            //   await Logout().logoutUser();
            //   await Logout().clearUser(key: "user_logged_in");
            //
            //   Navigator.pop(context);
            //   Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(builder: (context) => SignInOrRegister()),
            //         (route) => false,
            //   );
            // },
            // onTap: () async {
            //   // Perform the logout actions
            //   await Logout().logoutUser();
            //   await Logout().clearUser(key: "user_logged_in");
            //
            //   Future.delayed(Duration.zero, () {
            //     Navigator.pushAndRemoveUntil(
            //       context,
            //       MaterialPageRoute(builder: (context) => SignInOrRegister()),
            //           (route) => false, // Remove all routes from the stack
            //     );
            //   });
            // },

            onTap: () async {
              // Perform the logout actions
              await Logout().logoutUser();
              await Logout().clearUser(key: "user_logged_in");

              await AppRouter.logoutUser(context);
            },


          ),
        ],
      ),
    );
  }
}

// import 'dart:io';
//
// import 'package:black_box/extra/test/sign_in_or_register.dart';
// import 'package:black_box/screen_page/tutor/tutor_main_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
//
// import '../../cores/cores.dart';
// import '../../model/school/school.dart';
// import '../../model/user/user.dart';
// import '../../preference/logout.dart';
//
// class DrawerWidget extends StatefulWidget {
//   const DrawerWidget({Key? key}) : super(key: key);
//
//   @override
//   _DrawerWidgetState createState() => _DrawerWidgetState();
// }
//
// class _DrawerWidgetState extends State<DrawerWidget> {
//   String? userName;
//   String? userPhone;
//   String? userEmail;
//   File? _selectedImage;
//   bool _showSaveButton = false;
//   User? _user, _user_data;
//   final _formKey = GlobalKey<FormState>();
//   String? sid;
//   School? school;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }
//
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//         _showSaveButton = true;
//         _saveProfilePicture(pickedFile.path);  // Save the image path
//       });
//     }
//   }
//
//   Future<void> _saveProfilePicture(String path) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('profile_picture-${_user?.uniqueid!}', path);
//   }
//
//   Future<void> _loadUserData() async {
//     Logout logout = Logout();
//     User? user = await logout.getUserDetails(key: 'user_data');
//     Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
//     Map<String, dynamic>? schoolMap = await logout.getSchool(key: 'school_data');
//
//     if (userMap != null) {
//       User user_data = User.fromMap(userMap);
//       setState(() {
//         _user_data = user_data;
//       });
//     } else {
//       print("User map is null");
//     }
//
//     if (schoolMap != null) {
//       School schoolData = School.fromMap(schoolMap);
//       setState(() {
//         _user = user;
//         school = schoolData;
//         sid = school?.sId;
//         print(schoolData.sId);
//       });
//     } else {
//       print("School data is null");
//     }
//
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? userDataString = prefs.getString('user_logged_in');
//     String? imagePath = prefs.getString('profile_picture-${_user?.uniqueid!}');
//
//     if (userDataString != null) {
//       Map<String, dynamic> userData = jsonDecode(userDataString);
//       setState(() {
//         userName = userData['uname'];
//         userPhone = userData['phone'];
//         userEmail = userData['email'];
//         if (imagePath != null) {
//           _selectedImage = File(imagePath);
//         }
//       });
//     }
//   }
//
//   Widget _buildDrawerTile(IconData icon, String title, Widget page) {
//     return ListTile(
//       leading: Icon(icon, color: Theme.of(context).primaryColor),
//       title: Text(
//         title,
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//       ),
//       onTap: () {
//         Navigator.pop(context);
//         Navigator.push(context, MaterialPageRoute(builder: (context) => page));
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: <Widget>[
//           DrawerHeader(
//             decoration: const BoxDecoration(
//               color: AppColors.lightPrimaryColor,
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 GestureDetector(
//                   onTap: _pickImage,
//                   child: CircleAvatar(
//                     radius: 40,
//                     backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
//                     child: _selectedImage == null
//                         ? const Icon(
//                       Icons.person_pin_circle_sharp,
//                       size: 60,
//                       color: Colors.white,
//                     )
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   userName ?? 'T A S N I M',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.phone, size: 14, color: Colors.white),
//                       const SizedBox(width: 4),
//                       Text(
//                         userPhone ?? '+008 1800-445566',
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(width: 15),
//                       const Icon(Icons.email_outlined, size: 14, color: Colors.white),
//                       const SizedBox(width: 4),
//                       Text(
//                         userEmail ?? 'r@gmail.com',
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildDrawerTile(Icons.person_2, 'Tuition Tracker', TutorMainScreen()),
//           // _buildDrawerTile(Icons.account_box, 'B L A C K B O X', BlackBoxOnline()),
//           ListTile(
//             leading: const Icon(Icons.logout, color: Colors.red),
//             title: const Text(
//               'L O G O U T',
//               style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             onTap: () async {
//               await Logout().logoutUser();
//               await Logout().clearUser(key: "user_logged_in");
//
//               Navigator.pop(context);
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (context) => SignInOrRegister()),
//                     (route) => false,
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }