import 'package:get/get.dart';

import '../repository/mess_bazar_repository.dart';
import '../repository/mess_fee_repository.dart';
import '../repository/mess_meal_repository.dart';
import '../repository/mess_others_fee_repository.dart';
import '../repository/mess_payment_repository.dart';
import '../repository/mess_print_repository.dart';
import '../repository/mess_repository.dart';
import '../repository/mess_user_repository.dart';


class MessRepositoryProvider {
  // Singleton instance
  static final MessRepositoryProvider instance = MessRepositoryProvider._();

  MessRepositoryProvider._();

  // Lazy initialized repositories singletons
  late final Future<MessMainRepository> messMainRepository = MessMainRepository.init();
  late final Future<MessUserRepository> messUserRepository = MessUserRepository.init();
  late final Future<BazarListRepository> bazarListRepository = BazarListRepository.init();
  late final Future<MyMealsRepository> myMealsRepository = MyMealsRepository.init();
  late final Future<AccountPrintRepository> accountPrintRepository = AccountPrintRepository.init();
  late final Future<MessFeesRepository> messFeesRepository = MessFeesRepository.init();
  late final Future<OthersFeeRepository> othersFeeRepository = OthersFeeRepository.init();
  late final Future<PaymentRepository> paymentRepository = PaymentRepository.init();
}
