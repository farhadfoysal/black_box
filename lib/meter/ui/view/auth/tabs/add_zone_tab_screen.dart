import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/login_provider.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Your Zone',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your location to find nearby services',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Zone Selection Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Option
                    GestureDetector(
                      onTap: () {
                        // Handle current location selection
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use Current Location',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Automatically detect your zone',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider with "OR" text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Manual Zone Selection
                    Text(
                      'Select Zone Manually',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<LoginProvider>(
                      builder: (context, state, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButton<String>(
                            value: state.selected,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: colors.primary,
                            ),
                            style: theme.textTheme.bodyLarge,
                            items: state.dropDownList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                state.changeSelectedItem(value);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          tabController.animateTo(tabController.index + 1);
                          context
                              .read<LoginProvider>()
                              .changeTabIndex(tabController.index + 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../providers/login_provider.dart';
// import '../../../widgets/custom_button.dart';
// import '../../../widgets/custom_drop_down.dart';
// import '../../../widgets/custom_title_subtitle.dart';
//
// class AddZoneTabScreen extends StatelessWidget {
//   final TabController tabController;
//   final LoginProvider provider;
//
//   const AddZoneTabScreen({
//     Key? key,
//     required this.tabController,
//     required this.provider,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 10,
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const CustomTitleSubTitle(
//               title: 'Select Zone',
//               subTitle: 'Sign in to continue',
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Select Zone',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 5),
//             Consumer<LoginProvider>(builder: (context, state, child) {
//               return CustomDropDown(
//                 value: state.selected,
//                 dropDownList: state.dropDownList,
//                 onChanged: (value) {
//                   if (value != null) {
//                     state.changeSelectedItem(value);
//                   }
//                 },
//               );
//             }),
//             const SizedBox(height: 20),
//             CustomButton(
//               title: 'Next',
//               onPressed: () {
//                 tabController.animateTo(tabController.index + 1);
//                 context
//                     .read<LoginProvider>()
//                     .changeTabIndex(tabController.index + 1);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
