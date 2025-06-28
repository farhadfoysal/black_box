import 'package:black_box/meter/ui/view/receipt/widget/doted_line.dart';
import 'package:black_box/meter/ui/view/receipt/widget/thick_corner.dart';
import 'package:flutter/material.dart';

import '../../../model/meter_model.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/balance_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/payment_summary.dart';
import '../home_nav/home_nav_screen.dart';

class ReceiptScreen extends StatelessWidget {
  final MeterModel meterInfo;
  final String amount;

  const ReceiptScreen({
    Key? key,
    required this.meterInfo,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AppBarWidget(title: 'Receipt'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                            ),
                            child: BalanceWidget(
                              title: 'Available Balance',
                              balance: meterInfo.balance + double.parse(amount),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              ThickCorner(),
                              Expanded(
                                child: DottedLine(),
                              ),
                              ThickCorner(isRight: true),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Column(
                              children: [
                                PaymentSummary(
                                  mainAmount: double.parse(amount),
                                  isReceipt: true,
                                  meterInfo: meterInfo,
                                ),
                                const SizedBox(height: 20),
                                CustomButton(
                                  title: 'Download Receipt',
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const HomeNavScreen(),
                                      ),
                                          // (Route<dynamic> route) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
