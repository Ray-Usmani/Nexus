import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../state/app_state.dart';

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
  int _selectedIcon = 0;

  // Icons available for selection
  static const _icons = [
    Icons.shopping_cart_outlined,
    Icons.restaurant_outlined,
    Icons.local_gas_station_outlined,
    Icons.flight_outlined,
    Icons.home_outlined,
    Icons.bolt_outlined,
    Icons.fitness_center_outlined,
    Icons.directions_car_outlined,
    Icons.pets_outlined,
    Icons.movie_outlined,
    Icons.school_outlined,
    Icons.medical_services_outlined,
    Icons.checkroom_outlined,
    Icons.card_giftcard_outlined,
    Icons.subscriptions_outlined,
  ];

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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.line, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.bg3,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 20, color: AppColors.t2),
                    ),
                  ),
                  const Spacer(),
                  Text('New Tag', style: AppText.h2.copyWith(fontSize: 20)),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  // Tag Name field (floating label style)
                  _FloatingLabelField(
                    controller: _nameController,
                    label: 'Tag Name',
                    hint: 'e.g. Groceries, Gym, Work trip…',
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Create a descriptive name for your new category.',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Color Picker ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Visual Identity', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              'COLOR',
                              style: AppText.label.copyWith(color: AppColors.t3, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(color: AppColors.t1, width: 2.5)
                                      : null,
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: selected
                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Icon Picker ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Iconography', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              'SYMBOL',
                              style: AppText.label.copyWith(color: AppColors.t3, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemCount: _icons.length,
                          itemBuilder: (_, i) {
                            final selected = i == _selectedIcon;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedIcon = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.amber : AppColors.bg3,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.amber.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _icons[i],
                                  size: 22,
                                  color: selected ? AppColors.onAmber : AppColors.t2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Fixed bottom action bar ──────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.bg0.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(color: AppColors.line.withValues(alpha: 0.3)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.onAmber,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    elevation: 0,
                  ),
                  child: Text(
                    'CREATE TAG',
                    style: AppText.label.copyWith(
                      color: AppColors.onAmber,
                      fontSize: 13,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating-label text field matching the design spec.
class _FloatingLabelField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  const _FloatingLabelField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: AppText.body.copyWith(fontSize: 16),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppText.bodyMuted.copyWith(fontSize: 14),
        filled: true,
        fillColor: AppColors.bg1,
        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        labelStyle: AppText.labelMd.copyWith(color: AppColors.t3),
        floatingLabelStyle: AppText.labelMd.copyWith(color: AppColors.amber),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
