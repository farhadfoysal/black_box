
import 'package:black_box/meter/model/user_model.dart';

class MeterModel {
  String accountNo, meterNo, sequenceNo;
  double balance;
  UserModel user;

  MeterModel({
    required this.accountNo,
    required this.meterNo,
    required this.sequenceNo,
    required this.balance,
    required this.user,
  });
}
