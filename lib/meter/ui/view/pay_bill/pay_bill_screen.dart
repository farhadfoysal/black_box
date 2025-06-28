import 'package:black_box/meter/ui/view/pay_bill/widgets/money_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/money_data.dart';
import '../../../model/meter_model.dart';
import '../../../model/money_model.dart';
import '../../widgets/account_info_widget.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/balance_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/user_info_widget.dart';
import '../review/review_screen.dart';

class PayBillScreen extends StatelessWidget {
  final MeterModel meterInfo;

  const PayBillScreen({
    Key? key,
    required this.meterInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController moneyController = TextEditingController();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AppBarWidget(title: 'Pay Bill'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BalanceWidget(
                            title: 'Available Balance',
                            balance: meterInfo.balance,
                          ),
                          const SizedBox(height: 10),
                          UserInfoWidget(
                            name: meterInfo.user.name,
                            address: meterInfo.user.address,
                          ),
                          const SizedBox(height: 10),
                          AccountInfoWidget(
                            accountNo: meterInfo.accountNo,
                            meterNo: meterInfo.meterNo,
                            sequenceNo: meterInfo.sequenceNo,
                            sequenceTitle: 'Seq No.',
                          ),
                          const SizedBox(height: 10),
                          CustomInputField(
                            title: 'Enter Amount',
                            hintText: '1000',
                            icon: FontAwesomeIcons.bangladeshiTakaSign,
                            controller: moneyController,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 28,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              itemCount: MoneyData.moneyList.length,
                              itemBuilder: (context, index) {
                                MoneyModel money = MoneyData.moneyList[index];
                                return MoneyWidget(
                                  amount: money.amount,
                                  onTap: () {
                                    moneyController.text = money.amount;
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            title: 'Next',
                            onPressed: () {
                              if (moneyController.text.isNotEmpty) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ReviewScreen(
                                      meterInfo: meterInfo,
                                      amount: moneyController.text,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter amount first'),
                                  ),
                                );
                              }
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
      ),
    );
  }
}
