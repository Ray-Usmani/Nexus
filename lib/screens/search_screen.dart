import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textController = TextEditingController();
  String? _categoryId;
  String? _tagId;
  List<TransactionModel> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final state = context.read<AppState>();
    final results = await state.search(
      text: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
      categoryId: _categoryId,
      tagId: _tagId,
    );
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        title: Text('Search', style: AppText.h2),
        iconTheme: const IconThemeData(color: AppColors.t1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _textController,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: 'Note, amount…',
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _categoryId,
            dropdownColor: AppColors.bg2,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any category')),
              ...state.categories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: _tagId,
            dropdownColor: AppColors.bg2,
            decoration: const InputDecoration(labelText: 'Tag'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any tag')),
              ...state.tags.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
            ],
            onChanged: (v) => setState(() => _tagId = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _search,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.bg0),
            child: const Text('Search'),
          ),
          const SizedBox(height: 20),
          if (_searched && _results.isEmpty)
            const EmptyState(emoji: '🔍', title: 'No matches', subtitle: 'Try different filters.')
          else
            ..._results.map((t) {
              final cat = state.categoryById(t.categoryId);
              final tags = state.tagsForIds(t.tagIds);
              return TransactionTile(
                transaction: t,
                category: cat,
                tags: tags,
                onTap: () => _showDetail(context, t),
              );
            }),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TransactionModel t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatCurrency(t.amount), style: AppText.numberLarge()),
            Text(t.note.isEmpty ? 'No note' : t.note, style: AppText.body),
            Text(DateFormat('MMM d, yyyy HH:mm').format(t.date), style: AppText.caption),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await context.read<AppState>().deleteTransaction(t.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _search();
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.negative)),
            ),
          ],
        ),
      ),
    );
  }
}
