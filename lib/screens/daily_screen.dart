import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/search_icon_button.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dailyCats = state.categoriesBySection(CategorySection.daily);
    final dayExpenses = state.expensesForDay(_selectedDay)
        .where((e) => dailyCats.any((c) => c.id == e.categoryId))
        .toList();
    final dayTotal = dayExpenses.fold(0.0, (s, e) => s + e.amount);

    // Group transactions by category
    final Map<String, List<TransactionModel>> grouped = {};
    for (final e in dayExpenses) {
      grouped.putIfAbsent(e.categoryId, () => []).add(e);
    }

    final isToday = DateUtils.isSameDay(_selectedDay, DateTime.now());

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Top App Bar ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.amberBright.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.person, size: 20, color: AppColors.amber),
                  ),
                  const Spacer(),
                  Text(
                    'SpendWise',
                    style: AppText.h2.copyWith(color: AppColors.amber, letterSpacing: -0.5),
                  ),
                  const Spacer(),
                  const SearchIconButton(),
                ],
              ),
            ),
          ),

          // ── Calendar ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
                ),
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2035),
                  focusedDay: _selectedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  calendarFormat: _format,
                  onFormatChanged: (f) => setState(() => _format = f),
                  onDaySelected: (selected, _) => setState(() => _selectedDay = selected),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    titleTextStyle: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    formatButtonTextStyle: AppText.label.copyWith(color: AppColors.amber, fontSize: 10),
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(color: AppColors.line.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.t2, size: 20),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.t2, size: 20),
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultTextStyle: AppText.body.copyWith(fontSize: 13, color: AppColors.t1),
                    weekendTextStyle: AppText.body.copyWith(fontSize: 13, color: AppColors.t3),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.amberBright,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: AppText.body.copyWith(
                      color: AppColors.onAmberBright,
                      fontWeight: FontWeight.w700,
                    ),
                    todayDecoration: BoxDecoration(
                      border: Border.all(color: AppColors.amber, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: AppText.body.copyWith(color: AppColors.amber),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Summary Card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SummaryCard(
                total: dayTotal,
                label: isToday ? 'Total Spent Today' : DateFormat('EEEE, MMM d').format(_selectedDay),
              ),
            ),
          ),

          // ── List Header & Quick-Add Chips ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Text('Timeline', style: AppText.h2.copyWith(fontSize: 20)),
                  const Spacer(),
                  // Filter button
                  GestureDetector(
                    onTap: () => _showFilterSheet(context, dailyCats),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bg4,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune, size: 16, color: AppColors.amber),
                          const SizedBox(width: 6),
                          Text(
                            'FILTER',
                            style: AppText.label.copyWith(color: AppColors.amber, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick-add chips ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: dailyCats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => CategoryChip(
                  category: dailyCats[i],
                  onTap: () => _quickAdd(context, dailyCats[i].id, dailyCats[i].name),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Grouped Transactions ─────────────────────────────────────
          if (dayExpenses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  emoji: '📭',
                  title: 'No expenses',
                  subtitle: 'Tap a category above or use the Add button.',
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final catId = grouped.keys.elementAt(i);
                  final txns = grouped[catId]!;
                  final cat = state.categoryById(catId);
                  final groupTotal = txns.fold(0.0, (s, e) => s + e.amount);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _CategoryGroup(
                      category: cat,
                      transactions: txns,
                      groupTotal: groupTotal,
                      state: state,
                    ),
                  );
                },
                childCount: grouped.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, List<CategoryModel> cats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Quick Add', style: AppText.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((c) => CategoryChip(
                    category: c,
                    onTap: () {
                      Navigator.pop(context);
                      _quickAdd(context, c.id, c.name);
                    },
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, String categoryId, String name) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $name'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppText.body,
          decoration: const InputDecoration(hintText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.amber)),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.amber)),
          ),
        ],
      ),
    );
    if (amount != null && context.mounted) {
      await context.read<AppState>().addTransaction(
            amount: amount,
            note: name,
            categoryId: categoryId,
            date: _selectedDay,
          );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final String label;

  const _SummaryCard({required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                style: AppText.label.copyWith(color: AppColors.t3, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AnimatedCurrency(
                value: total,
                style: AppText.numberLarge().copyWith(
                  fontSize: 42,
                  color: AppColors.t1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: total > 0
                      ? AppColors.negativeContainer.withValues(alpha: 0.25)
                      : AppColors.bg4,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: total > 0
                        ? AppColors.negative.withValues(alpha: 0.2)
                        : AppColors.line.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      total > 0 ? Icons.trending_up : Icons.check_circle_outline,
                      size: 14,
                      color: total > 0 ? AppColors.negative : AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      total > 0 ? 'Expenses recorded' : 'No expenses yet',
                      style: AppText.label.copyWith(
                        color: total > 0 ? AppColors.negative : AppColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final CategoryModel? category;
  final List<TransactionModel> transactions;
  final double groupTotal;
  final AppState state;

  const _CategoryGroup({
    required this.category,
    required this.transactions,
    required this.groupTotal,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.amberBright.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category?.icon ?? '📦',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  category?.name ?? 'Other',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '−${formatCurrency(groupTotal)}',
                  style: AppText.body.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.bg4),
          // Transactions
          ...transactions.map((tx) {
            final tags = state.tagsForIds(tx.tagIds);
            return _TransactionRow(
              transaction: tx,
              category: category,
              tags: tags,
            );
          }),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final List tags;

  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg5),
            ),
            alignment: Alignment.center,
            child: Text(category?.icon ?? '📝', style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isEmpty ? (category?.name ?? 'Expense') : transaction.note,
                  style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(transaction.date),
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '−${formatCurrency(transaction.amount)}',
            style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.t1),
          ),
        ],
      ),
    );
  }
}
