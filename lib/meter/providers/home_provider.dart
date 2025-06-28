
import 'package:flutter/cupertino.dart';

import '../ui/view/history/history_screen.dart';
import '../ui/view/home/home_screen.dart';
import '../ui/view/profile/profile_screen.dart';
import '../ui/view/usage/usage_screen.dart';

class HomeProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get getCurrentIndex => _currentIndex;

  void onTap(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  List<Widget> widgets = [
    const HomeScreen(),
    const UsageScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];
}
