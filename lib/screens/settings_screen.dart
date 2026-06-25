import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer_button.dart';
import '../widgets/search_icon_button.dart';
import '../widgets/profile_avatar.dart';
import 'new_tag_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Top App Bar ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const AppDrawerButton(),
                  const Spacer(),
                  Text('Settings', style: AppText.h2.copyWith(fontSize: 20)),
                  const Spacer(),
                  const SearchIconButton(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Profile Card ─────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Section: Account & Preferences ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
              child: Text(
                'ACCOUNT & PREFERENCES',
                style: AppText.label.copyWith(color: AppColors.amber, letterSpacing: 1.4),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SettingsGroup(
                tiles: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => _showNotificationsSheet(context, state),
                  ),
                  _SettingsTile(
                    icon: Icons.currency_exchange_outlined,
                    label: 'Currency',
                    trailing: Text(state.currencyLabel, style: AppText.labelMd.copyWith(color: AppColors.t3)),
                    onTap: () => _showCurrencySheet(context, state),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Section: Tags ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
              child: Text(
                'TAGS',
                style: AppText.label.copyWith(color: AppColors.amber, letterSpacing: 1.4),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...state.tags.map((t) => Chip(
                          label: Text(
                            t.name,
                            style: TextStyle(color: t.color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: t.color.withValues(alpha: 0.1),
                          deleteIcon: Icon(Icons.close, size: 14, color: t.color.withValues(alpha: 0.6)),
                          side: BorderSide(color: t.color.withValues(alpha: 0.3)),
                          onDeleted: () => state.deleteTag(t.id),
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: AppColors.amber),
                      label: Text(
                        'New tag',
                        style: AppText.labelMd.copyWith(color: AppColors.amber),
                      ),
                      backgroundColor: AppColors.amberBright.withValues(alpha: 0.1),
                      side: BorderSide(color: AppColors.amber.withValues(alpha: 0.3)),
                      onPressed: () => showNewTagSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Section: Security & Data ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
              child: Text(
                'SECURITY & DATA',
                style: AppText.label.copyWith(color: AppColors.amber, letterSpacing: 1.4),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SettingsGroup(
                tiles: [
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    label: 'Security',
                    subtitle: 'PIN & Biometrics',
                    onTap: () => _showSecuritySheet(context, state),
                  ),
                  _SettingsTile(
                    icon: Icons.download_outlined,
                    label: 'Data Export',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Section: Categories ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
              child: Text(
                'CATEGORIES',
                style: AppText.label.copyWith(color: AppColors.amber, letterSpacing: 1.4),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: CategorySection.values.map((s) => _SectionBlock(section: s)).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Section: Support ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
              child: Text(
                'SUPPORT',
                style: AppText.label.copyWith(color: AppColors.amber, letterSpacing: 1.4),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SettingsGroup(
                tiles: [
                  _SettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear all data',
                    subtitle: 'Remove transactions, goals, and tags',
                    onTap: () => _confirmClearData(context, state),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline,
                    label: 'Help Center',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: 'About SpendWise',
                    subtitle: 'Local-first · Offline',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Sign Out button ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.negative.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 20, color: AppColors.negative),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: AppText.body.copyWith(
                          color: AppColors.negative,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Clear all data?', style: AppText.h2.copyWith(fontSize: 18)),
        content: Text(
          'This permanently deletes all transactions, budget plans, goals, fixed expenses, and tags. Categories and settings are kept.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.clearAllUserData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All records cleared')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
  }

  void _showCurrencySheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Select currency', style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ...AppState.currencyOptions.map((option) {
            final selected = state.currencyCode == option.code;
            return ListTile(
              title: Text(option.label, style: AppText.body),
              trailing: selected ? const Icon(Icons.check, color: AppColors.amber) : null,
              onTap: () async {
                await state.setCurrency(option.code, option.symbol, option.locale);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Notifications', style: AppText.h2.copyWith(fontSize: 18)),
                ),
                SwitchListTile(
                  title: Text('Daily reminder', style: AppText.body),
                  subtitle: Text('8:00 PM expense log reminder', style: AppText.caption),
                  value: state.notificationsDaily,
                  activeThumbColor: AppColors.amber,
                  onChanged: (v) async {
                    await state.setNotificationsDaily(v);
                    await NotificationService.instance.applyPreferences(
                      dailyEnabled: v,
                      weeklyEnabled: state.notificationsWeekly,
                    );
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text('Weekly summary', style: AppText.body),
                  subtitle: Text('Monday 9:00 AM budget review', style: AppText.caption),
                  value: state.notificationsWeekly,
                  activeThumbColor: AppColors.amber,
                  onChanged: (v) async {
                    await state.setNotificationsWeekly(v);
                    await NotificationService.instance.applyPreferences(
                      dailyEnabled: state.notificationsDaily,
                      weeklyEnabled: v,
                    );
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text('Overspend alerts', style: AppText.body),
                  subtitle: Text('Notify when an envelope goes over budget', style: AppText.caption),
                  value: state.notificationsOverspend,
                  activeThumbColor: AppColors.amber,
                  onChanged: (v) async {
                    await state.setNotificationsOverspend(v);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSecuritySheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Security', style: AppText.h2.copyWith(fontSize: 18)),
                ),
                SwitchListTile(
                  title: Text('Biometric lock', style: AppText.body),
                  subtitle: Text('Require fingerprint or Face ID to open the app', style: AppText.caption),
                  value: state.biometricsEnabled,
                  activeThumbColor: AppColors.amber,
                  onChanged: (v) async {
                    if (v) {
                      final supported = await AuthService.instance.canUseBiometrics();
                      if (!context.mounted) return;
                      if (!supported) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometrics not available on this device')),
                        );
                        return;
                      }
                      final ok = await AuthService.instance.authenticate(
                        reason: 'Enable biometric lock for SpendWise',
                      );
                      if (!ok) return;
                    }
                    await state.setBiometricsEnabled(v);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const ProfileAvatar(size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Profile', style: AppText.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to change photo · Offline mode',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.t3),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (file == null || !context.mounted) return;
    await context.read<AppState>().setProfileImageFromFile(file.path);
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> tiles;

  const _SettingsGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 58),
                color: AppColors.line.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.bg3,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.amber),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.caption),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppColors.t3, size: 20),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              section.name.toUpperCase(),
              style: AppText.caption.copyWith(color: AppColors.t3, letterSpacing: 1.2, fontSize: 10),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < cats.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Text(cats[i].icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(cats[i].name, style: AppText.body.copyWith(fontSize: 14)),
                        ),
                        if (!cats[i].isDefault)
                          GestureDetector(
                            onTap: () => state.deleteCategory(cats[i].id),
                            child: const Icon(Icons.delete_outline, size: 18, color: AppColors.t3),
                          ),
                      ],
                    ),
                  ),
                  if (i < cats.length - 1)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: 42),
                      color: AppColors.line.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
