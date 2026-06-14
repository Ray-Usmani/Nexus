import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          SectionLabel(DateFormat('MMMM yyyy').format(_selectedDay)),
          const SizedBox(height: 4),
          Text('Daily Tracking', style: AppText.display),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
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
                titleTextStyle: AppText.body.copyWith(fontWeight: FontWeight.w700),
                formatButtonTextStyle: AppText.caption.copyWith(color: AppColors.lime),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.t2, size: 20),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.t2, size: 20),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: AppText.body.copyWith(fontSize: 13),
                weekendTextStyle: AppText.body.copyWith(fontSize: 13, color: AppColors.t3),
                selectedDecoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                selectedTextStyle: AppText.body.copyWith(color: AppColors.bg0, fontWeight: FontWeight.w700),
                todayDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.lime),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: AppText.body.copyWith(color: AppColors.lime),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('EEEE, MMM d').format(_selectedDay), style: AppText.h2),
              Text(formatCurrency(dayTotal), style: AppText.numberMedium(color: AppColors.negative)),
            ],
          ),
          const SizedBox(height: 12),
          const SectionLabel('Quick add'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dailyCats.map((c) {
              return CategoryChip(
                category: c,
                onTap: () => _quickAdd(context, c.id, c.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Transactions'),
          const SizedBox(height: 10),
          if (dayExpenses.isEmpty)
            const EmptyState(emoji: '📭', title: 'No daily expenses', subtitle: 'Food, transport, shopping only.')
          else
            ...dayExpenses.map((e) {
              final cat = state.categoryById(e.categoryId);
              final tags = state.tagsForIds(e.tagIds);
              return TransactionTile(transaction: e, category: cat, tags: tags);
            }),
        ],
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, String categoryId, String name) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Add $name', style: AppText.h2),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppText.body,
          decoration: const InputDecoration(hintText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
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
