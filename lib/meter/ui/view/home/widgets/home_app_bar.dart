import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../utils/image_utils.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Md. Al-Amin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Badge(
              position: BadgePosition.topEnd(
                top: -9,
                end: -9,
              ),
              badgeStyle: const BadgeStyle(
                padding: EdgeInsets.all(4),
              ),
              child: SvgPicture.asset(
                ImageUtils.icNotification,
                width: 18,
                height: 18,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
