import 'package:flutter/material.dart';

import '../../../../model/profile_option_model.dart';

class ProfileOption extends StatelessWidget {
  final ProfileOptionModel profileOption;

  const ProfileOption({
    Key? key,
    required this.profileOption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(
        horizontal: -4,
        vertical: -2,
      ),
      title: Text(
        profileOption.title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: profileOption.color.withOpacity(0.2),
        child: Icon(
          profileOption.icon,
          size: 12,
          color: profileOption.color,
        ),
      ),
      horizontalTitleGap: 3,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
      ),
    );
  }
}
