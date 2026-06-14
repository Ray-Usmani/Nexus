import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';
import 'goals_screen.dart';
import 'timeline_screen.dart';
import 'new_tag_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const SectionLabel('Preferences'),
          const SizedBox(height: 4),
          Text('Settings', style: AppText.display),
          const SizedBox(height: 20),
          _LinkTile(
            icon: Icons.timeline_rounded,
            title: 'Timeline & History',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimelineScreen())),
          ),
          _LinkTile(
            icon: Icons.flag_rounded,
            title: 'Savings Goals',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Tags'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...state.tags.map((t) => Chip(
                    label: Text(t.name, style: TextStyle(color: t.color, fontSize: 12)),
                    backgroundColor: AppColors.bg2,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => state.deleteTag(t.id),
                  )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: AppColors.lime),
                label: const Text('New tag', style: TextStyle(color: AppColors.lime)),
                backgroundColor: AppColors.bg2,
                onPressed: () => showNewTagSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionLabel('Categories by section'),
          const SizedBox(height: 10),
          ...CategorySection.values.map((section) => _SectionBlock(section: section)),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('About'),
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/logo.png', width: 72, height: 72),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Nexus', style: AppText.body),
                Text('Local-first · Offline', style: AppText.bodyMuted.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lime, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppText.body)),
          const Icon(Icons.chevron_right, color: AppColors.t3, size: 18),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final CategorySection section;
  const _SectionBlock({required this.section});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = state.categoriesBySection(section);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.name.toUpperCase(), style: AppText.label),
          const SizedBox(height: 8),
          ...cats.map((c) => AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(c.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c.name, style: AppText.body)),
                    if (!c.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.t3),
                        onPressed: () => state.deleteCategory(c.id),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
