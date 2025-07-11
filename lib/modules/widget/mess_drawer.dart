import 'dart:io';

import 'package:black_box/screen_page/signin/sign_in_or_register.dart';
import 'package:black_box/screen_page/mess/settings/mess_settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../cores/cores.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';


class MessDrawer extends StatefulWidget {
  const MessDrawer({Key? key}) : super(key: key);

  @override
  _MessDrawerState createState() => _MessDrawerState();
}

class _MessDrawerState extends State<MessDrawer> {
  String? userName;
  String? userPhone;
  String? userEmail;
  File? _selectedImage;
  bool _showSaveButton = false;
  User? _user, _user_data;
  final _formKey = GlobalKey<FormState>();
  String? sid;
  School? school;


  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      leading: Icon(icon),
      title: Text(title),
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
          /*ListTile(
            leading: const Icon(Icons.school),
            title: const Text('S C H O O L  M E N U'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SchoolSetup()));
            },
          ),*/
          // _buildDrawerTile(Icons.account_box, 'B L A C K B O X', BlackBoxOnline()),
          // _buildDrawerTile(Icons.school, 'C L A S S  M E N U', ClassSetUpMenu()),
          // _buildDrawerTile(Icons.palette, 'P R O F I L E', const EditProfileScreen()),
          // _buildDrawerTile(Icons.bus_alert_outlined, 'B U S ', const BusSchedule()),
          // _buildDrawerTile(Icons.bloodtype, 'C L A S S  M A N A G E R', ClassManagerPage()),
          // _buildDrawerTile(Icons.note, 'N O T E S & T A S K S', NotesScreen()),
          // _buildDrawerTile(Icons.calendar_month_outlined, 'ACADEMIC - C A L E N D A R', AcademicCalender()),
          _buildDrawerTile(Icons.settings, 'S E T T I N G S', MessSettings()),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('L O G O U T'),
            onTap: () async {
              await Logout().logoutUser();
              await Logout().clearUser(key: "user_logged_in");

              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInOrRegister()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
