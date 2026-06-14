import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/app_database.dart';
import '../models/category_model.dart';
import '../models/fixed_allocation_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

class FixedScreen extends StatelessWidget {
  const FixedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fixedCats = state.categoriesBySection(CategorySection.fixed);
    final upcoming = state.upcomingDue;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const SectionLabel('Recurring'),
          const SizedBox(height: 4),
          Text('Fixed Expenses', style: AppText.display),
          const SizedBox(height: 16),
          if (upcoming.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Due soon'),
                  const SizedBox(height: 10),
                  ...upcoming.map((f) => _DueRow(allocation: f, state: state)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add, color: AppColors.lime, size: 18),
              label: const Text('Add allocation', style: TextStyle(color: AppColors.lime)),
            ),
          ),
          ...fixedCats.map((cat) {
            final items = state.fixedAllocations.where((f) => f.categoryId == cat.id).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(cat.name, style: AppText.h2),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('No ${cat.name.toLowerCase()} items', style: AppText.bodyMuted),
                  )
                else
                  ...items.map((f) => _FixedCard(allocation: f)),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddFixedSheet(),
    );
  }
}

class _DueRow extends StatelessWidget {
  final FixedAllocationModel allocation;
  final AppState state;
  const _DueRow({required this.allocation, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(allocation.name, style: AppText.body)),
          Text(DateFormat('MMM d').format(allocation.nextDueDate), style: AppText.caption),
          const SizedBox(width: 8),
          Text(formatCurrency(allocation.amount), style: AppText.numberSmall()),
        ],
      ),
    );
  }
}

class _FixedCard extends StatelessWidget {
  final FixedAllocationModel allocation;
  const _FixedCard({required this.allocation});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(allocation.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
              Text(formatCurrency(allocation.amount), style: AppText.numberSmall()),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${allocation.frequency.name} · Due ${DateFormat('MMM d, yyyy').format(allocation.nextDueDate)}',
            style: AppText.caption,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => state.logFixedAllocation(allocation),
                child: const Text('Log now', style: TextStyle(color: AppColors.lime)),
              ),
              TextButton(
                onPressed: () => state.deleteFixedAllocation(allocation.id),
                child: const Text('Delete', style: TextStyle(color: AppColors.t3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddFixedSheet extends StatefulWidget {
  @override
  State<_AddFixedSheet> createState() => _AddFixedSheetState();
}

class _AddFixedSheetState extends State<_AddFixedSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String? _categoryId;
  RecurFrequency _freq = RecurFrequency.monthly;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = state.categoriesBySection(CategorySection.fixed);
    _categoryId ??= cats.isNotEmpty ? cats.first.id : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New fixed allocation', style: AppText.h2),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(hintText: 'Name'), style: AppText.body),
          const SizedBox(height: 10),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Amount'),
            style: AppText.body,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            dropdownColor: AppColors.bg2,
            decoration: const InputDecoration(labelText: 'Category'),
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<RecurFrequency>(
            initialValue: _freq,
            dropdownColor: AppColors.bg2,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: RecurFrequency.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                .toList(),
            onChanged: (v) => setState(() => _freq = v ?? RecurFrequency.monthly),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(_amount.text);
              if (_name.text.isEmpty || amt == null || _categoryId == null) return;
              await state.addFixedAllocation(FixedAllocationModel(
                id: AppDatabase.instance.newId(),
                categoryId: _categoryId!,
                name: _name.text.trim(),
                amount: amt,
                frequency: _freq,
                nextDueDate: DateTime.now(),
              ));
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.bg0),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
