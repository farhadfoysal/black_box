import 'package:black_box/meter/ui/view/profile/widgets/profile_option.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/profile_option_data.dart';
import '../../../providers/home_provider.dart';
import '../../widgets/app_bar_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Consumer<HomeProvider>(
                builder: (context, state, child) {
                  return IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => state.onTap(0),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () {},
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile Header
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  primaryColor.withOpacity(0.2),
                                  secondaryColor.withOpacity(0.2),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: surfaceColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                const CircleAvatar(
                                  radius: 48,
                                  backgroundImage: NetworkImage(
                                    'https://avatars.githubusercontent.com/alamin-karno',
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Md. Al-Amin',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+8801621893919',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onSurfaceColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.1),
                              secondaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: secondaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Premium Member',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Account Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: List.generate(
                          ProfileOptionData.profileOptions.length,
                              (index) => Column(
                            children: [
                              ProfileOption(
                                profileOption:
                                ProfileOptionData.profileOptions[index],
                              ),
                              if (index <
                                  ProfileOptionData.profileOptions.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.grey.shade200,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Support Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Support',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.help_outline,
                              color: primaryColor),
                          title: Text('Help Center',
                              style: theme.textTheme.bodyLarge),
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey.shade400),
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade200,
                          indent: 16,
                          endIndent: 16,
                        ),
                        ListTile(
                          leading: Icon(Icons.info_outline,
                              color: primaryColor),
                          title: Text('About Us',
                              style: theme.textTheme.bodyLarge),
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey.shade400),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('Log Out',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}