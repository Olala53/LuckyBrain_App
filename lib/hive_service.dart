import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_model.dart';

class HiveService {
  static const String accountsBoxName = 'accounts';

  static Future<void> initHive() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AccountAdapter());
    }

    await Hive.openBox<Account>(accountsBoxName);
  }

  static Future<Box<Account>> getAccountsBox() async {
    if (!Hive.isBoxOpen(accountsBoxName)) {
      return await Hive.openBox<Account>(accountsBoxName);
    }
    return Hive.box<Account>(accountsBoxName);
  }

  static Future<void> addAccount(Account account) async {
    final box = await getAccountsBox();
    await box.add(account);
  }

  static Future<List<Account>> getAllAccounts() async {
    final box = await getAccountsBox();
    return box.values.toList();
  }

  static Future<void> deleteAccount(int index) async {
    final box = await getAccountsBox();
    await box.deleteAt(index);
  }
}
