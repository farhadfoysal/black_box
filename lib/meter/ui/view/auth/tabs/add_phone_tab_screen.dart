import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/login_provider.dart';
import '../../../../utils/image_utils.dart';

class AddPhoneTabScreen extends StatelessWidget {
  final TabController tabController;
  final LoginProvider provider;

  const AddPhoneTabScreen({
    Key? key,
    required this.tabController,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController phoneController = TextEditingController();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Banner with gradient overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        ImageUtils.appBanner,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sign in to access your account',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Login Card
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
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your phone number',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We\'ll send you a verification code',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Phone Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '+880 1621893919',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

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
                          backgroundColor: theme.primaryColor,
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
              SizedBox(height: 24),

              // Alternative Options
              Center(
                child: Text(
                  'Or continue with',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: Icons.g_mobiledata,
                    color: Colors.red,
                    onPressed: () {},
                  ),
                  SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.facebook,
                    color: Colors.blue[800]!,
                    onPressed: () {},
                  ),
                  SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.apple,
                    color: Colors.black,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}


//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../providers/login_provider.dart';
// import '../../../../utils/image_utils.dart';
// import '../../../widgets/custom_button.dart';
// import '../../../widgets/custom_input_field.dart';
// import '../../../widgets/custom_title_subtitle.dart';
//
// class AddPhoneTabScreen extends StatelessWidget {
//   final TabController tabController;
//   final LoginProvider provider;
//
//   const AddPhoneTabScreen({
//     Key? key,
//     required this.tabController,
//     required this.provider,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     TextEditingController phoneController = TextEditingController();
//     return SingleChildScrollView(
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 10,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Container(
//                 clipBehavior: Clip.antiAlias,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Image.asset(ImageUtils.appBanner),
//               ),
//             ),
//             const SizedBox(height: 30),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const CustomTitleSubTitle(
//                     title: 'Welcome',
//                     subTitle: 'Sign in to continue',
//                   ),
//                   const SizedBox(height: 20),
//                   CustomInputField(
//                     controller: phoneController,
//                     title: 'Phone or User ID',
//                     hintText: '+880 1621893919',
//                     icon: Icons.call,
//                   ),
//                   const SizedBox(height: 20),
//                   CustomButton(
//                     title: 'Next',
//                     onPressed: () {
//                       tabController.animateTo(tabController.index + 1);
//                       context
//                           .read<LoginProvider>()
//                           .changeTabIndex(tabController.index + 1);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
