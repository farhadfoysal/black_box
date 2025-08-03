import 'package:flutter/material.dart';

import '../../../model/mess/account_print.dart';
import '../../../model/mess/bazar_list.dart';
import '../../../model/mess/mess_fees.dart';
import '../../../model/mess/mess_main.dart';
import '../../../model/mess/mess_user.dart';
import '../../../model/mess/my_meals.dart';
import '../../../model/mess/others_fee.dart';
import '../../../model/mess/payment.dart';
import '../../services/local/sqlite_mess_bazar_service.dart';
import '../../services/local/sqlite_mess_fee_service.dart';
import '../../services/local/sqlite_mess_main_service.dart';
import '../../services/local/sqlite_mess_meal_service.dart';
import '../../services/local/sqlite_mess_other_service.dart';
import '../../services/local/sqlite_mess_payment_service.dart';
import '../../services/local/sqlite_mess_print_service.dart';
import '../../services/local/sqlite_mess_user_service.dart';
import '../../services/online/firebase_mess_bazar_service.dart';
import '../../services/online/firebase_mess_fee_service.dart';
import '../../services/online/firebase_mess_main_service.dart';
import '../../services/online/firebase_mess_meal_service.dart';
import '../../services/online/firebase_mess_other_service.dart';
import '../../services/online/firebase_mess_payment_service.dart';
import '../../services/online/firebase_mess_print_service.dart';
import '../../services/online/firebase_mess_user_service.dart';


// ... similarly import other services

class DatabaseProvider with ChangeNotifier {
  // Firebase services
  final FirebaseMessMainService _firebaseMessMainService = FirebaseMessMainService();
  final FirebaseMessUserService _firebaseMessUserService = FirebaseMessUserService();
  final FirebaseBazarListService _firebaseBazarListService = FirebaseBazarListService();
  final FirebaseMyMealsService _firebaseMyMealsService = FirebaseMyMealsService();
  final FirebaseAccountPrintService _firebaseAccountPrintService = FirebaseAccountPrintService();
  final FirebaseMessFeeService _firebaseMessFeesService = FirebaseMessFeeService();
  final FirebaseOthersFeeService _firebaseOthersFeeService = FirebaseOthersFeeService();
  final FirebasePaymentService _firebasePaymentService = FirebasePaymentService();

  // SQLite services
  final SQLiteMessMainService _sqliteMessMainService = SQLiteMessMainService();
  final SQLiteMessUserService _sqliteMessUserService = SQLiteMessUserService();
  final SQLiteBazarListService _sqliteBazarListService = SQLiteBazarListService();
  final SqliteMessMealService _sqliteMyMealsService = SqliteMessMealService();
  final SQLiteAccountPrintService _sqliteAccountPrintService = SQLiteAccountPrintService();
  final SQLiteMessFeesService _sqliteMessFeesService = SQLiteMessFeesService();
  final SQLiteOthersFeeService _sqliteOthersFeeService = SQLiteOthersFeeService();
  final SQLitePaymentService _sqlitePaymentService = SQLitePaymentService();

  // Current selected mess (example usage)
  MessMain? _currentMess;
  MessMain? get currentMess => _currentMess;
  void setCurrentMess(MessMain? mess) {
    _currentMess = mess;
    notifyListeners();
  }

  // === MessMain operations ===
  Future<String> createMessMain(MessMain mess) =>
      _firebaseMessMainService.create(mess);
  Future<void> updateMessMain(MessMain mess) =>
      _firebaseMessMainService.update(mess.messId!, mess);
  Future<void> deleteMessMain(String id) =>
      _firebaseMessMainService.delete(id);
  Future<MessMain?> getMessMain(String id) =>
      _sqliteMessMainService.get(id);  // Prefer local read
  Future<List<MessMain>> getAllMessMains() =>
      _sqliteMessMainService.getAll(); // Prefer local read
  Stream<MessMain?> watchMessMain(String id) =>
      _sqliteMessMainService.watch(id); // Local realtime stream
  Stream<List<MessMain>> watchAllMessMains() =>
      _sqliteMessMainService.watchAll();

  // === MessUser operations ===
  Future<String> createMessUser(MessUser user) =>
      _firebaseMessUserService.create(user);
  Future<void> updateMessUser(MessUser user) =>
      _firebaseMessUserService.update(user.uniqueId!, user);
  Future<void> deleteMessUser(String id) =>
      _firebaseMessUserService.delete(id);
  Future<MessUser?> getMessUser(String id) =>
      _sqliteMessUserService.get(id);
  Future<List<MessUser>> getAllMessUsers() =>
      _sqliteMessUserService.getAll();
  Future<List<MessUser>> getMessUsersByMess(String messId) =>
      _sqliteMessUserService.getAll().then(
            (users) => users.where((u) => u.messId == messId).toList(),
      );
  Stream<MessUser?> watchMessUser(String id) =>
      _sqliteMessUserService.watch(id);
  Stream<List<MessUser>> watchAllMessUsers() =>
      _sqliteMessUserService.watchAll();
  Stream<List<MessUser>> watchMessUsersByMess(String messId) =>
      _sqliteMessUserService.watchByMess(messId);

  // === BazarList operations ===
  Future<String> createBazarList(BazarList bazarList) =>
      _firebaseBazarListService.create(bazarList);
  Future<void> updateBazarList(BazarList bazarList) =>
      _firebaseBazarListService.update(bazarList.listId!, bazarList);
  Future<void> deleteBazarList(String id) =>
      _firebaseBazarListService.delete(id);
  Future<BazarList?> getBazarList(String id) =>
      _sqliteBazarListService.get(id);
  Future<List<BazarList>> getAllBazarLists() =>
      _sqliteBazarListService.getAll();
  Future<List<BazarList>> getBazarListsByMess(String messId) =>
      _sqliteBazarListService.getAll().then(
            (lists) => lists.where((l) => l.messId == messId).toList(),
      );
  Stream<BazarList?> watchBazarList(String id) =>
      _sqliteBazarListService.watch(id);
  Stream<List<BazarList>> watchAllBazarLists() =>
      _sqliteBazarListService.watchAll();
  Stream<List<BazarList>> watchBazarListsByMess(String messId) =>
      _sqliteBazarListService.watchByMess(messId);

  // === MyMeals operations ===
  Future<String> createMyMeal(MyMeals meal) =>
      _firebaseMyMealsService.create(meal);
  Future<void> updateMyMeal(MyMeals meal) =>
      _firebaseMyMealsService.update(meal.id!.toString(), meal);
  Future<void> deleteMyMeal(String id) =>
      _firebaseMyMealsService.delete(id);
  Future<MyMeals?> getMyMeal(String id) =>
      _sqliteMyMealsService.get(id);
  Future<List<MyMeals>> getAllMyMeals() =>
      _sqliteMyMealsService.getAll();
  Future<List<MyMeals>> getMyMealsByMess(String messId) =>
      _sqliteMyMealsService.getAll().then(
            (meals) => meals.where((m) => m.messId == messId).toList(),
      );
  Stream<MyMeals?> watchMyMeal(String id) =>
      _sqliteMyMealsService.watch(id);
  Stream<List<MyMeals>> watchAllMyMeals() =>
      _sqliteMyMealsService.watchAll();
  Stream<List<MyMeals>> watchMyMealsByMess(String messId) =>
      _sqliteMyMealsService.watchByMess(messId);

  // === AccountPrint operations ===
  Future<String> createAccountPrint(AccountPrint accountPrint) =>
      _firebaseAccountPrintService.create(accountPrint);
  Future<void> updateAccountPrint(AccountPrint accountPrint) =>
      _firebaseAccountPrintService.update(accountPrint.id!.toString(), accountPrint);
  Future<void> deleteAccountPrint(String id) =>
      _firebaseAccountPrintService.delete(id);
  Future<AccountPrint?> getAccountPrint(String id) =>
      _sqliteAccountPrintService.get(id);
  Future<List<AccountPrint>> getAllAccountPrints() =>
      _sqliteAccountPrintService.getAll();
  Future<List<AccountPrint>> getAccountPrintsByUser(String uniqueId) =>
      _sqliteAccountPrintService.getAll().then(
            (prints) => prints.where((p) => p.uniqueId == uniqueId).toList(),
      );
  Stream<AccountPrint?> watchAccountPrint(String id) =>
      _sqliteAccountPrintService.watch(id);
  Stream<List<AccountPrint>> watchAllAccountPrints() =>
      _sqliteAccountPrintService.watchAll();
  Stream<List<AccountPrint>> watchAccountPrintsByUser(String uniqueId) =>
      _sqliteAccountPrintService.watchByUser(uniqueId);

  // === MessFees operations ===
  Future<String> createMessFees(MessFees messFees) =>
      _firebaseMessFeesService.create(messFees);
  Future<void> updateMessFees(MessFees messFees) =>
      _firebaseMessFeesService.update(messFees.id!.toString(), messFees);
  Future<void> deleteMessFees(String id) =>
      _firebaseMessFeesService.delete(id);
  Future<MessFees?> getMessFee(String id) =>
      _sqliteMessFeesService.get(id);
  Future<List<MessFees>> getAllMessFees() =>
      _sqliteMessFeesService.getAll();
  Future<List<MessFees>> getMessFeesByMess(String messId) =>
      _sqliteMessFeesService.getAll().then(
            (fees) => fees.where((f) => f.messId == messId).toList(),
      );
  Stream<MessFees?> watchMessFee(String id) =>
      _sqliteMessFeesService.watch(id);
  Stream<List<MessFees>> watchAllMessFees() =>
      _sqliteMessFeesService.watchAll();
  Stream<List<MessFees>> watchMessFeesByMess(String messId) =>
      _sqliteMessFeesService.watchByMess(messId);

  // === OthersFee operations ===
  Future<String> createOthersFee(OthersFee othersFee) =>
      _firebaseOthersFeeService.create(othersFee);
  Future<void> updateOthersFee(OthersFee othersFee) =>
      _firebaseOthersFeeService.update(othersFee.id!.toString(), othersFee);
  Future<void> deleteOthersFee(String id) =>
      _firebaseOthersFeeService.delete(id);
  Future<OthersFee?> getOthersFee(String id) =>
      _sqliteOthersFeeService.get(id);
  Future<List<OthersFee>> getAllOthersFees() =>
      _sqliteOthersFeeService.getAll();
  Future<List<OthersFee>> getOthersFeesByMess(String messId) =>
      _sqliteOthersFeeService.getAll().then(
            (fees) => fees.where((f) => f.messId == messId).toList(),
      );
  Stream<OthersFee?> watchOthersFee(String id) =>
      _sqliteOthersFeeService.watch(id);
  Stream<List<OthersFee>> watchAllOthersFees() =>
      _sqliteOthersFeeService.watchAll();
  Stream<List<OthersFee>> watchOthersFeesByMess(String messId) =>
      _sqliteOthersFeeService.watchByMess(messId);

  // === Payment operations ===
  Future<String> createPayment(Payment payment) =>
      _firebasePaymentService.create(payment);
  Future<void> updatePayment(Payment payment) =>
      _firebasePaymentService.update(payment.id!.toString(), payment);
  Future<void> deletePayment(String id) =>
      _firebasePaymentService.delete(id);
  Future<Payment?> getPayment(String id) =>
      _sqlitePaymentService.get(id);
  Future<List<Payment>> getAllPayments() =>
      _sqlitePaymentService.getAll();
  Future<List<Payment>> getPaymentsByUser(String uniqueId) =>
      _sqlitePaymentService.getAll().then(
            (payments) => payments.where((p) => p.uniqueId == uniqueId).toList(),
      );
  Stream<Payment?> watchPayment(String id) =>
      _sqlitePaymentService.watch(id);
  Stream<List<Payment>> watchAllPayments() =>
      _sqlitePaymentService.watchAll();
  Stream<List<Payment>> watchPaymentsByUser(String uniqueId) =>
      _sqlitePaymentService.watchByUser(uniqueId);
}
