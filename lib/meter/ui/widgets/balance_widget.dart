import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/image_utils.dart';

class BalanceWidget extends StatelessWidget {
  final String title;
  final double balance;
  final Function()? onCancelTap;

  const BalanceWidget({
    Key? key,
    required this.title,
    required this.balance,
    this.onCancelTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            InkWell(
              onTap: onCancelTap ??
                      () {
                    Navigator.of(context).pop();
                  },
              child: FaIcon(
                FontAwesomeIcons.xmark,
                size: 16,
                color: Colors.grey.shade600,
              ),
            )
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            SvgPicture.asset(
              ImageUtils.icCoinSVG,
              height: 18,
              width: 18,
              color: balance > 0
                  ? Theme.of(context).primaryColor
                  : const Color(0xFFDF2528),
            ),
            const SizedBox(width: 5),
            Text(
              balance.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: balance > 0
                    ? Theme.of(context).primaryColor
                    : const Color(0xFFDF2528),
              ),
            ),
            Text(
              'BDT',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: balance > 0
                    ? Theme.of(context).primaryColor
                    : const Color(0xFFDF2528),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
