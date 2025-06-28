
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../providers/login_provider.dart';
import '../../utils/image_utils.dart';
import 'language_widget.dart';

class TapBarAppBar extends StatelessWidget {
  final TabController tabController;
  const TapBarAppBar({
    Key? key,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20.0,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                ImageUtils.appLogo,
                semanticsLabel: 'App Logo',
                width: 57,
              ),
              const LanguageWidget(),
            ],
          ),
          Consumer<LoginProvider>(builder: (context, state, child) {
            return Text(
              '${state.currentTabIndex}/${tabController.length}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade700,
              ),
            );
          }),
        ],
      ),
    );
  }
}
