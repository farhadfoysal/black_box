import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../providers/login_provider.dart';
import '../../home_nav/home_nav_screen.dart';

class AddMeterTabScreen extends StatelessWidget {
  final TabController tabController;
  final LoginProvider provider;

  const AddMeterTabScreen({
    Key? key,
    required this.tabController,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    TextEditingController meterController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Meter Selection Card
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
                    // QR Scanner Section
                    Consumer<LoginProvider>(
                      builder: (context, state, child) {
                        return state.isQrCode
                            ? Column(
                          children: [
                            Text(
                              'Scan Your Meter QR Code',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  MobileScanner(
                                    onDetect: (capture) {
                                      final List<Barcode> barcodes =
                                          capture.barcodes;
                                      for (final barcode in barcodes) {
                                        meterController.text =
                                        barcode.rawValue!;
                                        // Auto-submit if QR scanned
                                        if (barcode.rawValue!.isNotEmpty) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                              const HomeNavScreen(),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  Positioned(
                                    top: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: colors.primary
                                            .withOpacity(0.8),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Align QR code within frame',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Position the QR code in front of your camera',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        )
                            : const SizedBox();
                      },
                    ),

                    // Title Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Your Meter',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your meter details to continue',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Toggle Buttons
                    Consumer<LoginProvider>(
                      builder: (context, state, child) {
                        return Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => state.changeMeterScreen(false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !state.isQrCode
                                          ? colors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Manual Entry',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: !state.isQrCode
                                              ? Colors.white
                                              : colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => state.changeMeterScreen(true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: state.isQrCode
                                          ? colors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Scan QR Code',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: state.isQrCode
                                              ? Colors.white
                                              : colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Meter Input Field (only shown in manual mode)
                    Consumer<LoginProvider>(
                      builder: (context, state, child) {
                        return !state!.isQrCode
                            ? Column(
                          children: [
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.electric_meter,
                                      color: colors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: meterController,
                                        style: theme.textTheme.bodyLarge,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter meter number',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.qr_code_scanner,
                                        color: colors.primary,
                                      ),
                                      onPressed: () =>
                                          state.changeMeterScreen(true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Handle "Where to find meter number?"
                                },
                                child: Text(
                                  'Where to find meter number?',
                                  style: TextStyle(
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            : const SizedBox();
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const HomeNavScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Meter',
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
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../providers/login_provider.dart';
// import '../../../../utils/image_utils.dart';
// import '../../../widgets/custom_button.dart';
// import '../../../widgets/custom_input_field.dart';
// import '../../../widgets/custom_title_subtitle.dart';
// import '../../home_nav/home_nav_screen.dart';
//
// class AddMeterTabScreen extends StatelessWidget {
//   final TabController tabController;
//   final LoginProvider provider;
//
//   const AddMeterTabScreen({
//     Key? key,
//     required this.tabController,
//     required this.provider,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     TextEditingController meterController = TextEditingController();
//     return SingleChildScrollView(
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 10,
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Consumer<LoginProvider>(
//                     builder: (context, state, child) {
//                       return state.isQrCode
//                           ? Column(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Scanning Ongoing...',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headlineSmall
//                                 ?.copyWith(color: Colors.black54),
//                           ),
//                           const SizedBox(height: 5),
//                           Center(
//                             child: Stack(
//                               alignment: Alignment.center,
//                               children: [
//                                 Container(
//                                   height: 210,
//                                   width: 210,
//                                   color: Colors.transparent,
//                                   child: SvgPicture.asset(
//                                     ImageUtils.scannerBG,
//                                     fit: BoxFit.contain,
//                                   ),
//                                 ),
//                                 Container(
//                                   height: 200,
//                                   width: 200,
//                                   padding: const EdgeInsets.all(10),
//                                   child: MobileScanner(
//                                     onDetect: (capture) {
//                                       final List<Barcode> barcodes =
//                                           capture.barcodes;
//                                       for (final barcode in barcodes) {
//                                         meterController.text =
//                                         barcode.rawValue!;
//                                       }
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                         ],
//                       )
//                           : const SizedBox();
//                     },
//                   ),
//                   const CustomTitleSubTitle(
//                     title: 'Add Meter',
//                     subTitle: 'Please add your meter number',
//                   ),
//                   const SizedBox(height: 20),
//                   Consumer<LoginProvider>(
//                     builder: (context, state, child) {
//                       return Container(
//                         height: 42,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: InkWell(
//                                 onTap: () {
//                                   state.changeMeterScreen(false);
//                                 },
//                                 child: Container(
//                                   height: 42,
//                                   decoration: BoxDecoration(
//                                     color: state.isQrCode
//                                         ? Colors.transparent
//                                         : Theme.of(context).primaryColor,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       'Add Meter',
//                                       style: state.isQrCode
//                                           ? Theme.of(context)
//                                           .textTheme
//                                           .headlineSmall
//                                           : Theme.of(context)
//                                           .textTheme
//                                           .headlineSmall
//                                           ?.copyWith(
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               child: InkWell(
//                                 onTap: () {
//                                   state.changeMeterScreen(true);
//                                 },
//                                 child: Container(
//                                   height: 42,
//                                   decoration: BoxDecoration(
//                                     color: state.isQrCode
//                                         ? Theme.of(context).primaryColor
//                                         : Colors.transparent,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       'QR Code',
//                                       style: state.isQrCode
//                                           ? Theme.of(context)
//                                           .textTheme
//                                           .headlineSmall
//                                           ?.copyWith(
//                                         color: Colors.white,
//                                       )
//                                           : Theme.of(context)
//                                           .textTheme
//                                           .headlineSmall,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   CustomInputField(
//                     controller: meterController,
//                     title: 'Your Meter Number',
//                     hintText: '1234567890',
//                     icon: Icons.electric_meter_outlined,
//                   ),
//                   const SizedBox(height: 20),
//                   // CustomButton(
//                   //   title: 'Add',
//                   //   onPressed: () {
//                   //     Navigator.of(context).pushAndRemoveUntil(
//                   //       MaterialPageRoute(
//                   //         builder: (context) => const HomeNavScreen(),
//                   //       ),
//                   //           (Route<dynamic> route) => false,
//                   //     );
//                   //   },
//                   // ),
//                   CustomButton(
//                     title: 'Add',
//                     onPressed: () {
//                       Navigator.of(context).pushReplacement(
//                         MaterialPageRoute(
//                           builder: (context) => const HomeNavScreen(),
//                         ),
//                       );
//                     },
//                   )
//
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
