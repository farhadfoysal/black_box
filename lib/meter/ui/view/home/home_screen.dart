
import 'package:black_box/meter/ui/view/home/widgets/home_app_bar.dart';
import 'package:black_box/meter/ui/view/home/widgets/meter_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/meter_data.dart';
import '../../../providers/login_provider.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    LoginProvider provider = Provider.of<LoginProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const HomeAppBar(),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: MeterData.meterList.length,
              itemBuilder: (context, index) {
                return MeterStatus(
                  meter: MeterData.meterList[index],
                );
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () {
                  provider.changeTabIndex(3);
                  provider.changeTabScreen(true);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Add More Meter',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
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
