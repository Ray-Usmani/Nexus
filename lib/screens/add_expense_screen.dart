import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';
import 'new_tag_sheet.dart';
import 'voice_input_sheet.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amount = '0';
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  final _selectedTagIds = <String>{};
  String _paymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _saved = false;

  static const _paymentMethods = ['Cash', 'Card', 'UPI'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'back') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          if (_amount.contains('.')) {
            final parts = _amount.split('.');
            if (parts[1].length >= 2) return;
          }
          _amount += key;
        }
      }
    });
  }

  void _quickAdd(int v) {
    final current = double.tryParse(_amount) ?? 0;
    setState(() => _amount = (current + v).toStringAsFixed(current % 1 == 0 ? 0 : 2));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.amber,
            onPrimary: AppColors.onAmber,
            surface: AppColors.bg2,
            onSurface: AppColors.t1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(amount <= 0 ? 'Enter an amount' : 'Select a category'),
          backgroundColor: AppColors.bg3,
        ),
      );
      return;
    }

    await context.read<AppState>().addTransaction(
          amount: amount,
          note: _noteController.text.trim(),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          paymentMethod: _paymentMethod,
          tagIds: _selectedTagIds.toList(),
        );

    setState(() => _saved = true);
    _noteController.clear();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _amount = '0';
      _saved = false;
      _selectedDate = DateTime.now();
      _selectedTagIds.clear();
    });
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dailyCats = state.categoriesBySection(CategorySection.daily);

    if (_selectedCategoryId == null && dailyCats.isNotEmpty) {
      _selectedCategoryId = dailyCats.first.id;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Quick Add'),
                Text('Add Expense', style: AppText.display.copyWith(fontSize: 24)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.mic_rounded, color: AppColors.amber),
              onPressed: () => showVoiceInputSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const SectionLabel('Amount'),
              const SizedBox(height: 8),
              Text('${state.currencySymbol}$_amount', style: AppText.numberLarge().copyWith(fontSize: 42), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [100, 500, 1000, 5000].map((v) {
                  return _QuickChip(label: '+${v >= 1000 ? '${v ~/ 1000}K' : v}', onTap: () => _quickAdd(v));
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Keypad(onKeyTap: _onKeyTap),
        const SizedBox(height: 14),
        const SectionLabel('Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dailyCats.map((c) => CategoryChip(
                category: c,
                selected: c.id == _selectedCategoryId,
                onTap: () => setState(() => _selectedCategoryId = c.id),
              )).toList(),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Note'),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          style: AppText.body,
          decoration: const InputDecoration(hintText: 'What did you spend on?'),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Payment'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _paymentMethods.map((m) {
            final sel = m == _paymentMethod;
            return ChoiceChip(
              label: Text(m),
              selected: sel,
              selectedColor: AppColors.amberBright.withValues(alpha: 0.2),
              labelStyle: TextStyle(color: sel ? AppColors.amber : AppColors.t2),
              onSelected: (_) => setState(() => _paymentMethod = m),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Tags (optional)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...state.tags.map((t) => TagChip(
                  tag: t,
                  selected: _selectedTagIds.contains(t.id),
                  onTap: () => setState(() {
                    if (_selectedTagIds.contains(t.id)) {
                      _selectedTagIds.remove(t.id);
                    } else {
                      _selectedTagIds.add(t.id);
                    }
                  }),
                )),
            GestureDetector(
              onTap: () => showNewTagSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.t3),
                    const SizedBox(width: 4),
                    Text('New', style: AppText.bodyMuted.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          onTap: _pickDate,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate), style: AppText.body),
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.t2),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _saved ? AppColors.bg4 : AppColors.amber,
              foregroundColor: _saved ? AppColors.amber : AppColors.onAmber,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              elevation: _saved ? 0 : 2,
              shadowColor: AppColors.amber.withValues(alpha: 0.3),
            ),
            child: Text(
              _saved ? '✓ Saved!' : 'SAVE EXPENSE',
              style: AppText.label.copyWith(
                fontSize: 14,
                color: _saved ? AppColors.amber : AppColors.onAmber,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg3,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: AppText.numberSmall(color: AppColors.amber)),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String key) onKeyTap;
  const _Keypad({required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'back'],
    ];
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onKeyTap(key),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: key == 'back'
                            ? const Icon(Icons.backspace_outlined, size: 18, color: AppColors.t2)
                            : Text(key, style: AppText.numberMedium().copyWith(fontSize: 18)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
