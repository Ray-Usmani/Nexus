import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/transaction_detail_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String? _categoryId;
  String? _tagId;
  List<TransactionModel> _results = [];
  bool _searched = false;

  // Recent searches (static for now)
  final List<String> _recentSearches = ['Uber Eats', 'Groceries', 'Amazon'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    _focusNode.unfocus();
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

  void _quickSearch(String term) {
    _textController.text = term;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Task-focused header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.bg3,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.t1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Search', style: AppText.h2.copyWith(fontSize: 22)),
                  ],
                ),
              ),
            ),

            // ── Prominent search bar ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(Icons.search, color: AppColors.amber, size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: AppText.body.copyWith(fontSize: 15),
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: 'Search transactions, merchants…',
                            hintStyle: AppText.bodyMuted.copyWith(fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            filled: false,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showFilterSheet(context, state),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.bg3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.tune, size: 18, color: AppColors.t2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Recent Searches ─────────────────────────────────────
            if (!_searched) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'RECENT SEARCHES',
                    style: AppText.label.copyWith(color: AppColors.t3),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((term) => GestureDetector(
                          onTap: () => _quickSearch(term),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history, size: 14, color: AppColors.t3),
                                const SizedBox(width: 6),
                                Text(term, style: AppText.labelMd.copyWith(color: AppColors.t1)),
                              ],
                            ),
                          ),
                        )).toList(),
                  ),
                ),
              ),

              // ── Advanced Filters ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      _FilterCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date Range',
                        value: 'Last 30 Days',
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _FilterCard(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: _categoryId == null
                            ? 'All Categories'
                            : state.categoryById(_categoryId!)?.name ?? 'All',
                        onTap: () => _showCategoryPicker(context, state),
                      ),
                      const SizedBox(height: 8),
                      _FilterCard(
                        icon: Icons.payments_outlined,
                        label: 'Amount Range',
                        value: 'Any Amount',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Search Button ───────────────────────────────────────
            if (!_searched)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: ElevatedButton(
                    onPressed: _search,
                    child: const Text('SEARCH'),
                  ),
                ),
              ),

            // ── Results ─────────────────────────────────────────────
            if (_searched) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Text('Results', style: AppText.h2.copyWith(fontSize: 20)),
                      const Spacer(),
                      Text(
                        '${_results.length} transaction${_results.length == 1 ? '' : 's'}',
                        style: AppText.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              if (_results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    emoji: '🔍',
                    title: 'No matches',
                    subtitle: 'Try different keywords or clear the filters.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = _results[i];
                        final cat = state.categoryById(t.categoryId);
                        final tags = state.tagsForIds(t.tagIds);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ResultTile(
                            transaction: t,
                            category: cat,
                            tags: tags,
                            onTap: () => _showDetail(context, t),
                          ),
                        );
                      },
                      childCount: _results.length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppState state) {
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
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filters', style: AppText.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Category', style: AppText.label.copyWith(color: AppColors.t3)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              dropdownColor: AppColors.bg2,
              style: AppText.body,
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any category')),
                ...state.categories.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}')),
                ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _search();
                },
                child: const Text('APPLY FILTERS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          const DropdownMenuItem(value: null, child: Text('Any category')),
          ...state.categories.map((c) => ListTile(
                leading: Text(c.icon, style: const TextStyle(fontSize: 20)),
                title: Text(c.name, style: AppText.body),
                onTap: () {
                  setState(() => _categoryId = c.id);
                  Navigator.pop(context);
                  _search();
                },
              )),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TransactionModel t) {
    final cat = context.read<AppState>().categoryById(t.categoryId);
    showTransactionDetailSheet(context, t, category: cat, onDeleted: _search);
  }
}

class _FilterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.amberBright.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppText.label.copyWith(color: AppColors.t3, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: AppText.labelMd.copyWith(color: AppColors.t1)),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.t3, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final TransactionModel transaction;
  final dynamic category;
  final List tags;
  final VoidCallback onTap;

  const _ResultTile({
    required this.transaction,
    required this.category,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.bg4,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                category?.icon ?? '📝',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note.isEmpty ? (category?.name ?? 'Expense') : transaction.note,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (category != null)
                        Text(
                          category.name,
                          style: AppText.caption.copyWith(fontSize: 11),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 3,
                          height: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.t3,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(transaction.date),
                        style: AppText.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '−${formatCurrency(transaction.amount)}',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
