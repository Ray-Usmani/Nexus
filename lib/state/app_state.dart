import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_plan_model.dart';
import '../models/fixed_allocation_model.dart';
import '../models/goal_model.dart';
import '../models/tag_model.dart';

/// One detected anomaly — either an unusually large expense or a rarely
/// used category, surfaced on the Dashboard/Insights screens.
class Anomaly {
  final TransactionModel transaction;
  final String reason; // e.g. "3.2x your usual Food spend"
  Anomaly(this.transaction, this.reason);
}

/// ─────────────────────────────────────────────────────────────────────────
/// APP STATE
/// Central in-memory cache backed by [AppDatabase]. Every mutation writes
/// through to SQLite, refreshes the cache, then notifies listeners.
/// Houses all V2 logic: envelope budgeting, safe-to-spend, weekly review,
/// local anomaly detection, goals, smart search, and category management.
/// ─────────────────────────────────────────────────────────────────────────
class AppState extends ChangeNotifier {
  final _db = AppDatabase.instance;

  List<CategoryModel> _categories = [];
  List<TagModel> _tags = [];
  List<TransactionModel> _transactions = []; // focused month only
  List<BudgetPlanModel> _plans = [];          // focused month only
  List<FixedAllocationModel> _fixedAllocations = [];
  List<GoalModel> _goals = [];

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _loading = true;

  // ── Getters ────────────────────────────────────────────────────────────
  List<CategoryModel> get categories => _categories;
  List<TagModel> get tags => _tags;
  List<TransactionModel> get transactions => _transactions;
  List<BudgetPlanModel> get plans => _plans;
  List<FixedAllocationModel> get fixedAllocations => _fixedAllocations;
  List<GoalModel> get goals => _goals;
  DateTime get focusedMonth => _focusedMonth;
  bool get loading => _loading;

  List<CategoryModel> categoriesBySection(CategorySection s) =>
      _categories.where((c) => c.section == s).toList();

  CategoryModel? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  TagModel? tagById(String id) {
    for (final t in _tags) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<TagModel> tagsForIds(Iterable<String> ids) =>
      ids.map(tagById).whereType<TagModel>().toList();

  // ── Init ───────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _db.ensurePlansForMonth(_focusedMonth.year, _focusedMonth.month);
    await Future.wait([
      _refreshCategories(),
      _refreshTags(),
      _refreshPlans(),
      _refreshTransactions(),
      _refreshFixed(),
      _refreshGoals(),
    ]);
    await _processDueFixedAllocations();
    _loading = false;
    notifyListeners();
  }

  Future<void> _refreshCategories() async => _categories = await _db.getAllCategories();
  Future<void> _refreshTags() async => _tags = await _db.getAllTags();
  Future<void> _refreshPlans() async => _plans = await _db.getBudgetPlansForMonth(_focusedMonth.year, _focusedMonth.month);
  Future<void> _refreshFixed() async => _fixedAllocations = await _db.getAllFixedAllocations();
  Future<void> _refreshGoals() async => _goals = await _db.getAllGoals();

  Future<void> _refreshTransactions() async {
    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    _transactions = await _db.getTransactionsInRange(start, end);
  }

  Future<void> setFocusedMonth(DateTime month) async {
    _focusedMonth = DateTime(month.year, month.month, 1);
    await _db.ensurePlansForMonth(_focusedMonth.year, _focusedMonth.month);
    await Future.wait([_refreshPlans(), _refreshTransactions()]);
    notifyListeners();
  }

  // ═══════════════════════════ TRANSACTIONS ════════════════════════════════

  Future<void> addTransaction({
    required double amount,
    required String note,
    required String categoryId,
    required DateTime date,
    TransactionType type = TransactionType.expense,
    String paymentMethod = 'Cash',
    List<String> tagIds = const [],
  }) async {
    final txn = TransactionModel(
      id: _db.newId(),
      amount: amount,
      note: note,
      categoryId: categoryId,
      date: date,
      type: type,
      paymentMethod: paymentMethod,
      tagIds: tagIds,
    );
    await _db.insertTransaction(txn);
    if (date.year == _focusedMonth.year && date.month == _focusedMonth.month) {
      await _refreshTransactions();
    }
    notifyListeners();
  }

  /// Splits one transaction across multiple categories. [total] is shown
  /// in the Timeline as a single line item; [parts] are the per-category
  /// breakdowns used for budgeting/insights.
  Future<void> addSplitTransaction({
    required double total,
    required String note,
    required DateTime date,
    required List<SplitPart> parts,
    String paymentMethod = 'Cash',
    List<String> tagIds = const [],
  }) async {
    final parentId = _db.newId();
    final parent = TransactionModel(
      id: parentId,
      amount: total,
      note: note,
      categoryId: parts.first.categoryId, // representative category for display
      date: date,
      paymentMethod: paymentMethod,
      tagIds: tagIds,
      isSplitParent: true,
    );
    final children = parts
        .map((p) => TransactionModel(
              id: _db.newId(),
              amount: p.amount,
              note: p.note.isEmpty ? note : p.note,
              categoryId: p.categoryId,
              date: date,
              paymentMethod: paymentMethod,
              tagIds: tagIds,
              parentId: parentId,
            ))
        .toList();

    await _db.insertSplitTransaction(parent, children);
    if (date.year == _focusedMonth.year && date.month == _focusedMonth.month) {
      await _refreshTransactions();
    }
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await _db.updateTransaction(t);
    await _refreshTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await _refreshTransactions();
    notifyListeners();
  }

  /// Returns the list of "effective" expense rows for aggregation —
  /// split children replace their parent, non-split rows pass through.
  List<TransactionModel> get _effectiveExpenses {
    final children = _transactions.where((t) => t.parentId != null);
    final standalone = _transactions.where((t) => t.parentId == null && !t.isSplitParent);
    return [...standalone, ...children].where((t) => t.type == TransactionType.expense).toList();
  }

  /// Rows shown in Timeline/Daily — one line per parent (even if split).
  List<TransactionModel> get displayTransactions =>
      _transactions.where((t) => t.parentId == null).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> expensesForDay(DateTime day) => _effectiveExpenses
      .where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> displayForDay(DateTime day) => displayTransactions
      .where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day)
      .toList();

  // ═══════════════════════════ DAILY-SECTION TOTALS ════════════════════════

  /// IDs of categories that belong to the "Daily Tracking" section —
  /// Food, Transport, Shopping, Entertainment, Misc (+ any custom ones
  /// the user adds to that section).
  Set<String> get _dailyCategoryIds =>
      categoriesBySection(CategorySection.daily).map((c) => c.id).toSet();

  double get todayTotal {
    final now = DateTime.now();
    return expensesForDay(now)
        .where((e) => _dailyCategoryIds.contains(e.categoryId))
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get monthDailyTotal => _effectiveExpenses
      .where((e) => _dailyCategoryIds.contains(e.categoryId))
      .fold(0.0, (s, e) => s + e.amount);

  double get monthTotalAll => _effectiveExpenses.fold(0.0, (s, e) => s + e.amount);

  double get last7DaysTotal {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    return _effectiveExpenses.where((e) => e.date.isAfter(cutoff)).fold(0.0, (s, e) => s + e.amount);
  }

  double get dailyAverage {
    final now = DateTime.now();
    final isCurrentMonth = now.year == _focusedMonth.year && now.month == _focusedMonth.month;
    final daysElapsed = isCurrentMonth ? now.day : DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    if (daysElapsed == 0) return 0;
    return monthDailyTotal / daysElapsed;
  }

  Map<String, double> get dailyTotalsMap {
    final map = <String, double>{};
    for (final e in _effectiveExpenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  }

  // ═══════════════════════════ ENVELOPE BUDGETING ══════════════════════════

  /// Actual spend for a budget plan's category within the focused month.
  double actualForPlan(BudgetPlanModel plan) => _effectiveExpenses
      .where((e) => e.categoryId == plan.categoryId)
      .fold(0.0, (s, e) => s + e.amount);

  /// Aggregated envelope per category (sums multi-subcategory plans).
  List<EnvelopeData> get envelopes {
    final byCategory = <String, double>{};
    for (final p in _plans) {
      byCategory[p.categoryId] = (byCategory[p.categoryId] ?? 0) + p.plannedAmount;
    }
    return byCategory.entries.map((entry) {
      final category = categoryById(entry.key);
      final actual = _effectiveExpenses
          .where((e) => e.categoryId == entry.key)
          .fold(0.0, (s, e) => s + e.amount);
      return EnvelopeData(
        category: category,
        planned: entry.value,
        actual: actual,
      );
    }).toList()
      ..sort((a, b) => (b.category?.section.index ?? 0).compareTo(a.category?.section.index ?? 0));
  }

  double get totalPlannedDaily => _plans
      .where((p) => _dailyCategoryIds.contains(p.categoryId))
      .fold(0.0, (s, p) => s + p.plannedAmount);

  double get totalPlannedAll => _plans.fold(0.0, (s, p) => s + p.plannedAmount);

  // ═══════════════════════════ SAFE-TO-SPEND ═══════════════════════════════

  /// Remaining Monthly (Daily) Budget / Remaining Days — the headline
  /// metric for the Dashboard.
  double get safeToSpendPerDay {
    final now = DateTime.now();
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final isCurrentMonth = now.year == _focusedMonth.year && now.month == _focusedMonth.month;
    final remainingDays = isCurrentMonth ? (daysInMonth - now.day + 1) : daysInMonth;
    final remainingBudget = totalPlannedDaily - monthDailyTotal;
    if (remainingDays <= 0) return 0;
    return remainingBudget / remainingDays;
  }

  double get monthlyRemaining => totalPlannedAll - monthTotalAll;

  // ═══════════════════════════ END OF DAY SUMMARY ══════════════════════════

  EndOfDaySummary get endOfDaySummary {
    final today = expensesForDay(DateTime.now());
    final yesterday = expensesForDay(DateTime.now().subtract(const Duration(days: 1)));

    final todaySum = today.fold(0.0, (s, e) => s + e.amount);
    final yesterdaySum = yesterday.fold(0.0, (s, e) => s + e.amount);

    String? largestCategory;
    double largestAmount = 0;
    final byCategory = <String, double>{};
    for (final e in today) {
      byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
    }
    byCategory.forEach((catId, total) {
      if (total > largestAmount) {
        largestAmount = total;
        largestCategory = categoryById(catId)?.name;
      }
    });

    return EndOfDaySummary(
      totalSpent: todaySum,
      largestCategory: largestCategory,
      largestCategoryAmount: largestAmount,
      remainingBudget: safeToSpendPerDay,
      comparisonToYesterday: todaySum - yesterdaySum,
    );
  }

  // ═══════════════════════════ ANOMALY DETECTION ═══════════════════════════

  /// Flags today's expenses that are statistical outliers vs. the
  /// category's recent history, or that use a rarely-touched category.
  /// Purely local — no AI call required for this baseline check.
  List<Anomaly> get todaysAnomalies {
    final today = expensesForDay(DateTime.now());
    final anomalies = <Anomaly>[];

    // Build per-category history from last 90 days (across stored months
    // would require a wider query; for a single-user local app we use the
    // focused month's data plus today as a reasonable proxy).
    final history = <String, List<double>>{};
    for (final e in _effectiveExpenses) {
      history.putIfAbsent(e.categoryId, () => []).add(e.amount);
    }

    for (final t in today) {
      final amounts = history[t.categoryId] ?? [];
      if (amounts.length < 3) {
        anomalies.add(Anomaly(t, 'Rarely used category — only ${amounts.length} entr${amounts.length == 1 ? 'y' : 'ies'} this month'));
        continue;
      }
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((a) => (a - mean) * (a - mean)).reduce((a, b) => a + b) / amounts.length;
      final stddev = variance > 0 ? variance.sqrt() : 0;
      if (stddev > 0 && t.amount > mean + 2 * stddev) {
        final ratio = (t.amount / mean).toStringAsFixed(1);
        anomalies.add(Anomaly(t, '${ratio}x your usual ${categoryById(t.categoryId)?.name ?? 'category'} spend'));
      }
    }
    return anomalies;
  }

  // ═══════════════════════════ WEEKLY REVIEW ═══════════════════════════════

  WeeklyReview get weeklyReview {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    double thisWeekTotal = 0, lastWeekTotal = 0;
    final byCategory = <String, double>{};

    for (final e in _effectiveExpenses) {
      if (!e.date.isBefore(thisWeekStart) && e.date.isBefore(thisWeekStart.add(const Duration(days: 7)))) {
        thisWeekTotal += e.amount;
        byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
      } else if (!e.date.isBefore(lastWeekStart) && e.date.isBefore(thisWeekStart)) {
        lastWeekTotal += e.amount;
      }
    }

    String? biggestCategory;
    double biggestAmount = 0;
    byCategory.forEach((catId, total) {
      if (total > biggestAmount) {
        biggestAmount = total;
        biggestCategory = categoryById(catId)?.name;
      }
    });

    // Budget health score: average of (1 - usedFraction) across envelopes,
    // clamped 0-100. 100 = nothing spent yet, 0 = everything at/over budget.
    final envs = envelopes.where((e) => e.planned > 0).toList();
    double healthScore = 100;
    if (envs.isNotEmpty) {
      // 100 at 0% used, 50 at 100% used, 0 at 150%+ used.
      final avgFrac = envs.map((e) => (e.actual / e.planned)).reduce((a, b) => a + b) / envs.length;
      healthScore = (100 - avgFrac * 66.7).clamp(0, 100).toDouble();
    }

    return WeeklyReview(
      thisWeekTotal: thisWeekTotal,
      lastWeekTotal: lastWeekTotal,
      biggestCategory: biggestCategory,
      biggestCategoryAmount: biggestAmount,
      healthScore: healthScore,
    );
  }

  // ═══════════════════════════ CHARTS / TRENDS ═════════════════════════════

  Future<List<MapEntry<DateTime, double>>> lastNMonthsTotals(int count) async {
    final result = <MapEntry<DateTime, double>>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(_focusedMonth.year, _focusedMonth.month - i, 1);
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 1);
      final rows = await _db.getTransactionsInRange(start, end);
      final total = rows.where((r) => r.type == TransactionType.expense && r.parentId == null && !r.isSplitParent).fold(0.0, (s, e) => s + e.amount);
      final splitTotal = rows.where((r) => r.type == TransactionType.expense && r.parentId != null).fold(0.0, (s, e) => s + e.amount);
      result.add(MapEntry(m, total + splitTotal));
    }
    return result;
  }

  List<MapEntry<CategoryModel, double>> categoryBreakdown() {
    final byCategory = <String, double>{};
    for (final e in _effectiveExpenses) {
      byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
    }
    final entries = byCategory.entries
        .map((e) => MapEntry(categoryById(e.key), e.value))
        .where((e) => e.key != null)
        .map((e) => MapEntry(e.key!, e.value))
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<MapEntry<DateTime, double>> topSpendingDays({int count = 3}) {
    final totals = dailyTotalsMap;
    final entries = totals.entries.map((e) {
      final parts = e.key.split('-');
      return MapEntry(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])), e.value);
    }).toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(count).toList();
  }

  // ═══════════════════════════ CATEGORIES & TAGS ═══════════════════════════

  Future<void> addCategory({required String name, required String icon, required int colorIndex, required CategorySection section}) async {
    final c = CategoryModel(id: _db.newId(), name: name, icon: icon, colorIndex: colorIndex, section: section);
    await _db.insertCategory(c);
    await _refreshCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await _refreshCategories();
    notifyListeners();
  }

  Future<void> addTag(String name, int colorIndex) async {
    final t = TagModel(id: _db.newId(), name: name, colorIndex: colorIndex);
    await _db.insertTag(t);
    await _refreshTags();
    notifyListeners();
  }

  Future<void> deleteTag(String id) async {
    await _db.deleteTag(id);
    await _refreshTags();
    notifyListeners();
  }

  // ═══════════════════════════ BUDGET PLANS ════════════════════════════════

  Future<void> upsertPlan(BudgetPlanModel plan) async {
    await _db.upsertBudgetPlan(plan);
    await _refreshPlans();
    notifyListeners();
  }

  Future<void> addPlan({required String categoryId, required double plannedAmount, String subcategory = ''}) async {
    final plan = BudgetPlanModel(
      id: _db.newId(),
      categoryId: categoryId,
      subcategory: subcategory,
      plannedAmount: plannedAmount,
      month: _focusedMonth.month,
      year: _focusedMonth.year,
    );
    await _db.upsertBudgetPlan(plan);
    await _refreshPlans();
    notifyListeners();
  }

  Future<void> deletePlan(String id) async {
    await _db.deleteBudgetPlan(id);
    await _refreshPlans();
    notifyListeners();
  }

  Future<void> copyPreviousMonth() async {
    await _db.copyPreviousMonthPlans(_focusedMonth.year, _focusedMonth.month);
    await _refreshPlans();
    notifyListeners();
  }

  // ═══════════════════════════ FIXED ALLOCATIONS ═══════════════════════════

  Future<void> addFixedAllocation(FixedAllocationModel f) async {
    await _db.upsertFixedAllocation(f);
    await _refreshFixed();
    notifyListeners();
  }

  Future<void> updateFixedAllocation(FixedAllocationModel f) async {
    await _db.upsertFixedAllocation(f);
    await _refreshFixed();
    notifyListeners();
  }

  Future<void> deleteFixedAllocation(String id) async {
    await _db.deleteFixedAllocation(id);
    await _refreshFixed();
    notifyListeners();
  }

  /// Logs a fixed allocation as a transaction "now" and advances its
  /// next due date.
  Future<void> logFixedAllocation(FixedAllocationModel f) async {
    await addTransaction(
      amount: f.amount,
      note: f.name,
      categoryId: f.categoryId,
      date: DateTime.now(),
    );
    final updated = f.copyWith(nextDueDate: f.nextOccurrence());
    await updateFixedAllocation(updated);
  }

  /// On app open: auto-logs any [autoLog] allocations whose due date has
  /// passed, advancing them to the next occurrence.
  Future<void> _processDueFixedAllocations() async {
    final now = DateTime.now();
    for (final f in _fixedAllocations) {
      if (f.isActive && f.autoLog && f.frequency != RecurFrequency.once && !f.nextDueDate.isAfter(now)) {
        await addTransaction(
          amount: f.amount,
          note: f.name,
          categoryId: f.categoryId,
          date: f.nextDueDate,
        );
        final updated = f.copyWith(nextDueDate: f.nextOccurrence());
        await _db.upsertFixedAllocation(updated);
      }
    }
    await _refreshFixed();
  }

  /// Allocations due within the next 3 days — surfaced as reminders.
  List<FixedAllocationModel> get upcomingDue {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 3));
    return _fixedAllocations
        .where((f) => f.isActive && !f.nextDueDate.isAfter(soon))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  // ═══════════════════════════════ GOALS ═══════════════════════════════════

  Future<void> addGoal(GoalModel g) async {
    await _db.upsertGoal(g);
    await _refreshGoals();
    notifyListeners();
  }

  Future<void> updateGoal(GoalModel g) async {
    await _db.upsertGoal(g);
    await _refreshGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _db.deleteGoal(id);
    await _refreshGoals();
    notifyListeners();
  }

  // ═══════════════════════════ SMART SEARCH ════════════════════════════════

  Future<List<TransactionModel>> search({
    String? text,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? tagId,
  }) {
    return _db.searchTransactions(
      noteQuery: text,
      minAmount: minAmount,
      maxAmount: maxAmount,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      tagId: tagId,
    );
  }

  // ═══════════════════════════ AI CONTEXT EXPORT ═══════════════════════════

  /// Builds a compact JSON-able snapshot sent to the FastAPI backend for
  /// AI insights/chat. Only aggregates and recent transactions are sent —
  /// never the full historical database.
  Map<String, dynamic> buildAiContext() {
    return {
      'month': '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}',
      'monthTotalAll': monthTotalAll,
      'monthDailyTotal': monthDailyTotal,
      'totalPlannedAll': totalPlannedAll,
      'totalPlannedDaily': totalPlannedDaily,
      'safeToSpendPerDay': safeToSpendPerDay,
      'envelopes': envelopes.map((e) => {
            'category': e.category?.name ?? 'Unknown',
            'planned': e.planned,
            'actual': e.actual,
          }).toList(),
      'recentTransactions': displayTransactions.take(20).map((t) => {
            'amount': t.amount,
            'category': categoryById(t.categoryId)?.name ?? 'Unknown',
            'note': t.note,
            'date': t.date.toIso8601String(),
          }).toList(),
      'goals': _goals.map((g) => {
            'name': g.name,
            'target': g.targetAmount,
            'current': g.currentAmount,
          }).toList(),
    };
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) return 0;
    double x = this;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

/// Aggregated planned vs actual for one category — drives the circular
/// envelope rings on Dashboard + Planning.
class EnvelopeData {
  final CategoryModel? category;
  final double planned;
  final double actual;

  EnvelopeData({required this.category, required this.planned, required this.actual});

  double get fraction => planned > 0 ? actual / planned : 0;
  double get remaining => planned - actual;
}

class EndOfDaySummary {
  final double totalSpent;
  final String? largestCategory;
  final double largestCategoryAmount;
  final double remainingBudget;
  final double comparisonToYesterday;

  EndOfDaySummary({
    required this.totalSpent,
    required this.largestCategory,
    required this.largestCategoryAmount,
    required this.remainingBudget,
    required this.comparisonToYesterday,
  });
}

class WeeklyReview {
  final double thisWeekTotal;
  final double lastWeekTotal;
  final String? biggestCategory;
  final double biggestCategoryAmount;
  final double healthScore; // 0-100

  WeeklyReview({
    required this.thisWeekTotal,
    required this.lastWeekTotal,
    required this.biggestCategory,
    required this.biggestCategoryAmount,
    required this.healthScore,
  });

  double get changeVsLastWeek => lastWeekTotal > 0 ? (thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100 : 0;
}