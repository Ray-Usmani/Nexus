import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';

/// Parses simple voice-style phrases: "Spent 450 on lunch"
Future<void> showVoiceInputSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _VoiceInputSheet(),
  );
}

class _VoiceInputSheet extends StatefulWidget {
  const _VoiceInputSheet();

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet> {
  final _controller = TextEditingController();
  String _status = 'Type or paste: "Spent 450 on lunch"';

  void _parse() {
    final text = _controller.text.toLowerCase();
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    if (amountMatch == null) {
      setState(() => _status = 'Could not find an amount');
      return;
    }
    final amount = double.parse(amountMatch.group(1)!);
    final state = context.read<AppState>();
    final dailyCats = state.categoriesBySection(CategorySection.daily);

    CategoryModel? matched;
    for (final c in dailyCats) {
      if (text.contains(c.name.toLowerCase()) ||
          (c.name == 'Food' && (text.contains('lunch') || text.contains('dinner') || text.contains('food')))) {
        matched = c;
        break;
      }
    }
    matched ??= dailyCats.isNotEmpty ? dailyCats.first : null;

    if (matched == null) {
      setState(() => _status = 'No daily category found');
      return;
    }

    state.addTransaction(
      amount: amount,
      note: _controller.text.trim(),
      categoryId: matched.id,
      date: DateTime.now(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Voice / text input', style: AppText.h2),
          const SizedBox(height: 8),
          Text(_status, style: AppText.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            style: AppText.body,
            decoration: const InputDecoration(hintText: 'Spent 450 on lunch'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _parse,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.bg0),
            child: const Text('Parse & save'),
          ),
        ],
      ),
    );
  }
}
