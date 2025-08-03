import '../../../model/mess/account_print.dart';
import '../../../model/mess/bazar_list.dart';
import '../../../model/mess/mess_fees.dart';
import '../../../model/mess/mess_main.dart';
import '../../../model/mess/mess_user.dart';
import '../../../model/mess/my_meals.dart';
import '../../../model/mess/others_fee.dart';
import '../../../model/mess/payment.dart';

extension MessMainSync on MessMain {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  MessMain copyWithSyncStatus(String status) {
    return MessMain(
      id: id,
      mId: mId,
      messId: messId,
      messName: messName,
      messAddress: messAddress,
      messPass: messPass,
      messAdminId: messAdminId,
      mealUpdateStatus: mealUpdateStatus,
      adminPhone: adminPhone,
      startDate: startDate,
      sumOfAllTrx: sumOfAllTrx,
      uPerm: uPerm,
      qr: qr,
      currentMonth: currentMonth,
      syncStatus: status,
    );
  }
}

extension MessUserSync on MessUser {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  MessUser copyWithSyncStatus(String status) {
    return MessUser(
      id: id,
      uniqueId: uniqueId,
      userId: userId,
      phone: phone,
      email: email,
      userType: userType,
      phonePass: phonePass,
      messId: messId,
      activeStatus: activeStatus,
      bazarStart: bazarStart,
      bazarEnd: bazarEnd,
      qr: qr,
      img: img,
      syncStatus: status,
    );
  }
}

extension OthersFeeSync on OthersFee {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  OthersFee copyWithSyncStatus(String status) {
    return OthersFee(
      id: id,
      uniqueId: uniqueId,
      messId: messId,
      feeType: feeType,
      amount: amount,
      adminId: adminId,
      date: date,
      status: status,
      syncStatus: status,
    );
  }
}

extension MyMealsSync on MyMeals {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  MyMeals copyWithSyncStatus(String status) {
    return MyMeals(
      id: id,
      uniqueId: uniqueId,
      messId: messId,
      date: date,
      time: time,
      morning: morning,
      launce: launce,
      dinner: dinner,
      mealUpdate: mealUpdate,
      sumMeal: sumMeal,
      mealReset: mealReset,
      syncStatus: status,
    );
  }
}


extension AccountPrintSync on AccountPrint {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  AccountPrint copyWithSyncStatus(String status) {
    return AccountPrint(
      id: id,
      uniqueId: uniqueId,
      userName: userName,
      phone: phone,
      messMonthEx: messMonthEx,
      myExpense: myExpense,
      mealExpense: mealExpense,
      myMonthMeal: myMonthMeal,
      payOrReceive: payOrReceive,
      trxClearId: trxClearId,
      syncStatus: status,
    );
  }
}


extension MessFeesSync on MessFees {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  MessFees copyWithSyncStatus(String status) {
    return MessFees(
      id: id,
      messId: messId,
      feeType: feeType,
      amount: amount,
      adminId: adminId,
      date: date,
      status: this.status,
      syncStatus: status,
    );
  }
}


extension BazarListSync on BazarList {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  BazarList copyWithSyncStatus(String status) {
    return BazarList(
      id: id,
      listId: listId,
      uniqueId: uniqueId,
      messId: messId,
      phone: phone,
      listDetails: listDetails,
      amount: amount,
      dateTime: dateTime,
      adminNotify: adminNotify,
      syncStatus: status,
    );
  }
}


extension PaymentSync on Payment {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  Payment copyWithSyncStatus(String status) {
    return Payment(
      id: id,
      uniqueId: uniqueId,
      adminId: adminId,
      messId: messId,
      phone: phone,
      dateM: dateM,
      trxId: trxId,
      amount: amount,
      clearTrx: clearTrx,
      printing: printing,
      time: time,
      syncStatus: status,
    );
  }
}
