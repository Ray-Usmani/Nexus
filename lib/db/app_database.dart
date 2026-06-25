import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_plan_model.dart';
import '../models/fixed_allocation_model.dart';
import '../models/goal_model.dart';
import '../models/tag_model.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// LOCAL DATABASE (V2)
/// Single SQLite file (`expense_tracker_v2.db`) — everything lives
/// on-device. No network calls happen from this class; the FastAPI
/// backend (if configured) only ever receives ad-hoc, stateless context
/// payloads built by AiState — nothing is persisted server-side.
/// ─────────────────────────────────────────────────────────────────────────
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'expense_tracker_v2.db';
  static const _dbVersion = 1;

  static const tableTransactions = 'transactions';
  static const tableCategories   = 'categories';
  static const tableBudgetPlans  = 'budget_plans';
  static const tableFixed        = 'fixed_allocations';
  static const tableGoals        = 'goals';
  static const tableTags         = 'tags';
  static const tableSettings     = 'settings';

  final _uuid = const Uuid();
  String newId() => _uuid.v4();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableCategories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            colorIndex INTEGER NOT NULL,
            section TEXT NOT NULL,
            isDefault INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableTags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            colorIndex INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableTransactions (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            note TEXT NOT NULL,
            categoryId TEXT NOT NULL,
            date TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'expense',
            paymentMethod TEXT NOT NULL DEFAULT 'Cash',
            tagIds TEXT NOT NULL DEFAULT '',
            parentId TEXT,
            isSplitParent INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_txn_date ON $tableTransactions (date)');
        await db.execute('CREATE INDEX idx_txn_category ON $tableTransactions (categoryId)');
        await db.execute('CREATE INDEX idx_txn_parent ON $tableTransactions (parentId)');

        await db.execute('''
          CREATE TABLE $tableBudgetPlans (
            id TEXT PRIMARY KEY,
            categoryId TEXT NOT NULL,
            subcategory TEXT NOT NULL DEFAULT '',
            plannedAmount REAL NOT NULL,
            month INTEGER NOT NULL,
            year INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_plan_month ON $tableBudgetPlans (year, month)');

        await db.execute('''
          CREATE TABLE $tableFixed (
            id TEXT PRIMARY KEY,
            categoryId TEXT NOT NULL,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            frequency TEXT NOT NULL,
            nextDueDate TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            autoLog INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableGoals (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            targetAmount REAL NOT NULL,
            currentAmount REAL NOT NULL DEFAULT 0,
            deadline TEXT,
            colorIndex INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableSettings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await _seedDefaults(db);
      },
    );
  }

  Future<void> _seedDefaults(Database db) async {
    final batch = db.batch();

    final categories = defaultCategories(newId);
    for (final c in categories) {
      batch.insert(tableCategories, c.toMap());
    }

    final byName = {for (final c in categories) c.name: c.id};
    final now = DateTime.now();

    // Starter monthly plan — mirrors the original sheet's totals,
    // spread across the new category structure. User edits in Planning.
    final starterPlans = <BudgetPlanModel>[
      BudgetPlanModel(id: newId(), categoryId: byName['Food']!,         plannedAmount: 13500, month: now.month, year: now.year, subcategory: 'Weekdays'),
      BudgetPlanModel(id: newId(), categoryId: byName['Food']!,         plannedAmount: 16000, month: now.month, year: now.year, subcategory: 'Weekends'),
      BudgetPlanModel(id: newId(), categoryId: byName['Transport']!,    plannedAmount: 5500,  month: now.month, year: now.year, subcategory: 'Fuel'),
      BudgetPlanModel(id: newId(), categoryId: byName['Shopping']!,     plannedAmount: 5000,  month: now.month, year: now.year),
      BudgetPlanModel(id: newId(), categoryId: byName['Entertainment']!,plannedAmount: 5000,  month: now.month, year: now.year),
      BudgetPlanModel(id: newId(), categoryId: byName['Miscellaneous']!,plannedAmount: 5000,  month: now.month, year: now.year),
      BudgetPlanModel(id: newId(), categoryId: byName['Charity']!,      plannedAmount: 5000,  month: now.month, year: now.year),
      BudgetPlanModel(id: newId(), categoryId: byName['Savings']!,      plannedAmount: 20000, month: now.month, year: now.year),
      BudgetPlanModel(id: newId(), categoryId: byName['Investments']!,  plannedAmount: 10000, month: now.month, year: now.year),
      BudgetPlanModel(id: newId(), categoryId: byName['Subscriptions']!,plannedAmount: 5000,  month: now.month, year: now.year),
    ];
    for (final p in starterPlans) {
      batch.insert(tableBudgetPlans, p.toMap());
    }

    // Starter fixed allocations
    final starterFixed = <FixedAllocationModel>[
      FixedAllocationModel(id: newId(), categoryId: byName['Subscriptions']!, name: 'Coursera', amount: 2600, frequency: RecurFrequency.yearly, nextDueDate: DateTime(now.year, 1, 15), isActive: true),
      FixedAllocationModel(id: newId(), categoryId: byName['Investments']!, name: 'Mutual Fund SIP', amount: 5000, frequency: RecurFrequency.monthly, nextDueDate: DateTime(now.year, now.month, 5), isActive: true),
    ];
    for (final f in starterFixed) {
      batch.insert(tableFixed, f.toMap());
    }

    await batch.commit(noResult: true);
  }

  // ───────────────────────────── SETTINGS ─────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(tableSettings, where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(tableSettings, {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─────────────────────────────── CATEGORIES ─────────────────────────────

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final rows = await db.query(tableCategories, orderBy: 'section ASC, isDefault DESC, name ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<String> insertCategory(CategoryModel c) async {
    final db = await database;
    await db.insert(tableCategories, c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return c.id;
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(tableCategories, where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────── TAGS ──────────────────────────────────

  Future<List<TagModel>> getAllTags() async {
    final db = await database;
    final rows = await db.query(tableTags, orderBy: 'name ASC');
    return rows.map(TagModel.fromMap).toList();
  }

  Future<String> insertTag(TagModel t) async {
    final db = await database;
    await db.insert(tableTags, t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return t.id;
  }

  Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete(tableTags, where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────── TRANSACTIONS ─────────────────────────────

  Future<String> insertTransaction(TransactionModel t) async {
    final db = await database;
    await db.insert(tableTransactions, t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return t.id;
  }

  /// Inserts a parent (marked isSplitParent) plus one child row per split.
  Future<void> insertSplitTransaction(TransactionModel parent, List<TransactionModel> children) async {
    final db = await database;
    final batch = db.batch();
    batch.insert(tableTransactions, parent.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final c in children) {
      batch.insert(tableTransactions, c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateTransaction(TransactionModel t) async {
    final db = await database;
    await db.update(tableTransactions, t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(tableTransactions, where: 'id = ?', whereArgs: [id]);
    // Also remove any split children
    await db.delete(tableTransactions, where: 'parentId = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final rows = await db.query(tableTransactions, orderBy: 'date DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getTransactionsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query(
      tableTransactions,
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// Smart search across category name, note, tags, amount, and date —
  /// the categoryId/tag-name lookups are resolved by the caller (AppState
  /// holds the in-memory category/tag lists), so this just does the
  /// straightforward note/amount/date filtering at the SQL level.
  Future<List<TransactionModel>> searchTransactions({
    String? noteQuery,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? tagId,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (noteQuery != null && noteQuery.isNotEmpty) {
      where.add('note LIKE ?');
      args.add('%$noteQuery%');
    }
    if (minAmount != null) {
      where.add('amount >= ?');
      args.add(minAmount);
    }
    if (maxAmount != null) {
      where.add('amount <= ?');
      args.add(maxAmount);
    }
    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('date < ?');
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }
    if (tagId != null) {
      where.add('(tagIds = ? OR tagIds LIKE ? OR tagIds LIKE ? OR tagIds LIKE ?)');
      args.addAll([tagId, '$tagId,%', '%,$tagId', '%,$tagId,%']);
    }

    final rows = await db.query(
      tableTransactions,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  // ─────────────────────────────── BUDGET PLANS ───────────────────────────

  Future<List<BudgetPlanModel>> getBudgetPlansForMonth(int year, int month) async {
    final db = await database;
    final rows = await db.query(
      tableBudgetPlans,
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return rows.map(BudgetPlanModel.fromMap).toList();
  }

  Future<void> upsertBudgetPlan(BudgetPlanModel plan) async {
    final db = await database;
    await db.insert(tableBudgetPlans, plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBudgetPlan(String id) async {
    final db = await database;
    await db.delete(tableBudgetPlans, where: 'id = ?', whereArgs: [id]);
  }

  /// "Copy previous month" — duplicates last month's plan rows into the
  /// target month if the target month has no plans yet.
  Future<void> ensurePlansForMonth(int year, int month) async {
    final existing = await getBudgetPlansForMonth(year, month);
    if (existing.isNotEmpty) return;

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prev = await getBudgetPlansForMonth(prevYear, prevMonth);
    if (prev.isEmpty) return;

    final db = await database;
    final batch = db.batch();
    for (final p in prev) {
      final copy = BudgetPlanModel(
        id: newId(),
        categoryId: p.categoryId,
        subcategory: p.subcategory,
        plannedAmount: p.plannedAmount,
        month: month,
        year: year,
      );
      batch.insert(tableBudgetPlans, copy.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Explicit "copy previous month" trigger — overwrites/duplicates
  /// regardless of whether plans already exist (additive).
  Future<void> copyPreviousMonthPlans(int year, int month) async {
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prev = await getBudgetPlansForMonth(prevYear, prevMonth);

    final db = await database;
    // Clear current month plans first to avoid duplicates on repeat taps.
    await db.delete(tableBudgetPlans, where: 'year = ? AND month = ?', whereArgs: [year, month]);

    final batch = db.batch();
    for (final p in prev) {
      final copy = BudgetPlanModel(
        id: newId(),
        categoryId: p.categoryId,
        subcategory: p.subcategory,
        plannedAmount: p.plannedAmount,
        month: month,
        year: year,
      );
      batch.insert(tableBudgetPlans, copy.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────── FIXED ALLOCATIONS ──────────────────────────

  Future<List<FixedAllocationModel>> getAllFixedAllocations() async {
    final db = await database;
    final rows = await db.query(tableFixed, orderBy: 'nextDueDate ASC');
    return rows.map(FixedAllocationModel.fromMap).toList();
  }

  Future<void> upsertFixedAllocation(FixedAllocationModel f) async {
    final db = await database;
    await db.insert(tableFixed, f.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFixedAllocation(String id) async {
    final db = await database;
    await db.delete(tableFixed, where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────── GOALS ─────────────────────────────────

  Future<List<GoalModel>> getAllGoals() async {
    final db = await database;
    final rows = await db.query(tableGoals, orderBy: 'name ASC');
    return rows.map(GoalModel.fromMap).toList();
  }

  Future<void> upsertGoal(GoalModel g) async {
    final db = await database;
    await db.insert(tableGoals, g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete(tableGoals, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────── AGGREGATES ─────────────────────────────

  /// Wipes user-created records while keeping default categories and settings.
  Future<void> clearAllUserData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete(tableTransactions);
    batch.delete(tableBudgetPlans);
    batch.delete(tableFixed);
    batch.delete(tableGoals);
    batch.delete(tableTags);
    await batch.commit(noResult: true);
  }

  /// Category totals for a date range — used by Insights/Charts/AI context.
  Future<Map<String, double>> categoryTotals(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT categoryId, SUM(amount) as total
      FROM $tableTransactions
      WHERE date >= ? AND date < ? AND type = 'expense' AND parentId IS NULL AND isSplitParent = 0
      GROUP BY categoryId
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // Also include split children (parentId NOT NULL)
    final childRows = await db.rawQuery('''
      SELECT categoryId, SUM(amount) as total
      FROM $tableTransactions
      WHERE date >= ? AND date < ? AND type = 'expense' AND parentId IS NOT NULL
      GROUP BY categoryId
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final result = <String, double>{};
    for (final row in [...rows, ...childRows]) {
      final id = row['categoryId'] as String;
      final total = (row['total'] as num).toDouble();
      result[id] = (result[id] ?? 0) + total;
    }
    return result;
  }
}