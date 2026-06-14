import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

Future<void> showNewTagSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _NewTagSheet(),
  );
}

class _NewTagSheet extends StatefulWidget {
  const _NewTagSheet();

  @override
  State<_NewTagSheet> createState() => _NewTagSheetState();
}

class _NewTagSheetState extends State<_NewTagSheet> {
  final _nameController = TextEditingController();
  int _selectedColor = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await context.read<AppState>().addTag(name, _selectedColor);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.lineHi)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text('New Tag', style: AppText.h2.copyWith(fontSize: 20)),
            const SizedBox(height: 18),
            const SectionLabel('Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'e.g. Gym, Work trip...'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Colour'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(AppColors.catColors.length, (i) {
                final color = AppColors.catColors[i];
                final selected = i == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 32 : 26,
                    height: selected ? 32 : 26,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: AppColors.t1, width: 2) : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.bg0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Create Tag', style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.bg0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
