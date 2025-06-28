
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/login_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_drop_down.dart';
import '../../../widgets/custom_title_subtitle.dart';

class AddZoneTabScreen extends StatelessWidget {
  final TabController tabController;
  final LoginProvider provider;

  const AddZoneTabScreen({
    Key? key,
    required this.tabController,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomTitleSubTitle(
              title: 'Select Zone',
              subTitle: 'Sign in to continue',
            ),
            const SizedBox(height: 20),
            Text(
              'Select Zone',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Consumer<LoginProvider>(builder: (context, state, child) {
              return CustomDropDown(
                value: state.selected,
                dropDownList: state.dropDownList,
                onChanged: (value) {
                  if (value != null) {
                    state.changeSelectedItem(value);
                  }
                },
              );
            }),
            const SizedBox(height: 20),
            CustomButton(
              title: 'Next',
              onPressed: () {
                tabController.animateTo(tabController.index + 1);
                context
                    .read<LoginProvider>()
                    .changeTabIndex(tabController.index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}
