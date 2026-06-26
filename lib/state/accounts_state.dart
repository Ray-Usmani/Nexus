import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../models/account_model.dart';
import '../models/account_entry_model.dart';

/// Manages personal accounts (wallets/banks) independently from budget math.
class AccountsState extends ChangeNotifier {
  final _db = AppDatabase.instance;

  List<AccountModel> _accounts = [];
  final Map<String, List<AccountEntryModel>> _entriesByAccount = {};
  bool _loading = true;

  List<AccountModel> get accounts => _accounts;
  bool get loading => _loading;

  double get totalBalance => _accounts.fold(0.0, (sum, a) => sum + a.balance);

  List<AccountEntryModel> entriesFor(String accountId) =>
      _entriesByAccount[accountId] ?? const [];

  AccountModel? accountById(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> init() async {
    await _refreshAccounts();
    _loading = false;
    notifyListeners();
  }

  Future<void> _refreshAccounts() async {
    _accounts = await _db.getAllAccounts();
  }

  Future<void> _refreshEntries(String accountId) async {
    _entriesByAccount[accountId] = await _db.getEntriesForAccount(accountId);
  }

  Future<void> loadEntries(String accountId) async {
    await _refreshEntries(accountId);
    notifyListeners();
  }

  Future<void> addAccount({required String title, required double balance}) async {
    final account = AccountModel(
      id: _db.newId(),
      title: title.trim(),
      balance: balance,
      colorIndex: _accounts.length % 8,
      createdAt: DateTime.now(),
    );
    await _db.upsertAccount(account);
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> updateAccountTitle(AccountModel account, String title) async {
    await _db.upsertAccount(account.copyWith(title: title.trim()));
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    _entriesByAccount.remove(id);
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> recordDeposit({
    required String accountId,
    required double amount,
    required String note,
    DateTime? date,
  }) async {
    if (amount <= 0) return;
    final account = accountById(accountId);
    if (account == null) return;

    final entry = AccountEntryModel(
      id: _db.newId(),
      accountId: accountId,
      type: AccountEntryType.deposit,
      amount: amount,
      note: note.trim(),
      date: date ?? DateTime.now(),
    );

    await _db.insertAccountEntry(entry);
    await _db.updateAccountBalance(accountId, account.balance + amount);
    await _refreshAccounts();
    await _refreshEntries(accountId);
    notifyListeners();
  }

  Future<void> recordExpense({
    required String accountId,
    required double amount,
    required String note,
    DateTime? date,
  }) async {
    if (amount <= 0) return;
    final account = accountById(accountId);
    if (account == null) return;

    final entry = AccountEntryModel(
      id: _db.newId(),
      accountId: accountId,
      type: AccountEntryType.expense,
      amount: amount,
      note: note.trim(),
      date: date ?? DateTime.now(),
    );

    await _db.insertAccountEntry(entry);
    await _db.updateAccountBalance(accountId, account.balance - amount);
    await _refreshAccounts();
    await _refreshEntries(accountId);
    notifyListeners();
  }

  Future<void> recordTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String note,
    DateTime? date,
  }) async {
    if (amount <= 0 || fromAccountId == toAccountId) return;

    final from = accountById(fromAccountId);
    final to = accountById(toAccountId);
    if (from == null || to == null) return;

    final groupId = _db.newId();
    final when = date ?? DateTime.now();

    final outEntry = AccountEntryModel(
      id: _db.newId(),
      accountId: fromAccountId,
      type: AccountEntryType.transferOut,
      amount: amount,
      note: note.trim(),
      date: when,
      relatedAccountId: toAccountId,
      transferGroupId: groupId,
    );

    final inEntry = AccountEntryModel(
      id: _db.newId(),
      accountId: toAccountId,
      type: AccountEntryType.transferIn,
      amount: amount,
      note: note.trim(),
      date: when,
      relatedAccountId: fromAccountId,
      transferGroupId: groupId,
    );

    await _db.insertAccountEntry(outEntry);
    await _db.insertAccountEntry(inEntry);
    await _db.updateAccountBalance(fromAccountId, from.balance - amount);
    await _db.updateAccountBalance(toAccountId, to.balance + amount);
    await _refreshAccounts();
    await _refreshEntries(fromAccountId);
    await _refreshEntries(toAccountId);
    notifyListeners();
  }
}
