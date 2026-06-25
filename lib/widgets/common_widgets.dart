import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/tag_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';

String _currencySymbol = 'Rs.';
String _currencyLocale = 'en_PK';

/// Active currency symbol — updated when the user changes currency in settings.
String get currentCurrencySymbol => _currencySymbol;

void configureCurrency({required String symbol, required String locale}) {
  _currencySymbol = symbol;
  _currencyLocale = locale;
}

String formatCurrency(num value) => NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
      decimalDigits: 0,
    ).format(value);

/// Standard card container — obsidian surface, subtle amber border, rounded.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: AppColors.amber.withValues(alpha: 0.08),
        highlightColor: AppColors.amber.withValues(alpha: 0.04),
        child: card,
      ),
    );
  }
}

/// Section label — uppercase, letter-spaced, amber accent.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.label.copyWith(color: AppColors.amber, letterSpacing: 1.4),
    );
  }
}

/// Colored chip for a spending category.
class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : AppColors.bg2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : AppColors.line.withValues(alpha: 0.5),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: AppText.labelMd.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.t2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored chip showing a tag label.
class TagChip extends StatelessWidget {
  final TagModel tag;
  final bool selected;
  final VoidCallback? onTap;

  const TagChip({super.key, required this.tag, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = tag.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : AppColors.bg2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : AppColors.line.withValues(alpha: 0.5),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          tag.name,
          style: AppText.labelMd.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? color : AppColors.t2,
          ),
        ),
      ),
    );
  }
}

/// Tiny inline badge — used in transaction lists.
class TagBadge extends StatelessWidget {
  final TagModel tag;
  const TagBadge({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final color = tag.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Animated progress bar — fills from 0 to [fraction] on first build.
class AnimatedProgressBar extends StatefulWidget {
  final double fraction; // 0.0 - 1.0+ (can exceed 1 for over-budget)
  final Color color;
  final Color overColor;
  final Duration delay;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.overColor = AppColors.negative,
    this.delay = Duration.zero,
    this.height = 6,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _value = widget.fraction.clamp(0, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOver = widget.fraction > 1.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: widget.height,
        color: AppColors.bg4,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            widthFactor: _value,
            child: Container(
              decoration: BoxDecoration(
                color: isOver ? widget.overColor : widget.color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper since Flutter doesn't ship AnimatedFractionallySizedBox.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final double? heightFactor;
  final AlignmentGeometry alignment;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    this.heightFactor,
    this.alignment = Alignment.center,
    required this.child,
    required super.duration,
    super.curve = Curves.linear,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactorTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactorTween = visitor(
      _widthFactorTween,
      widget.widthFactor,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactorTween?.evaluate(animation) ?? widget.widthFactor,
      heightFactor: widget.heightFactor,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}

/// Number that counts up from 0 to [value] on first build.
class AnimatedCurrency extends StatefulWidget {
  final double value;
  final TextStyle style;
  final Duration duration;
  final Duration delay;
  final String? prefix;

  const AnimatedCurrency({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.prefix,
  });

  @override
  State<AnimatedCurrency> createState() => _AnimatedCurrencyState();
}

class _AnimatedCurrencyState extends State<AnimatedCurrency>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final symbol = widget.prefix ?? currentCurrencySymbol;
        final current = widget.value * _animation.value;
        return Text(
          '$symbol${NumberFormat('#,##0', _currencyLocale).format(current)}',
          style: widget.style,
        );
      },
    );
  }
}

/// Circular envelope indicator — planned vs used.
class EnvelopeRing extends StatelessWidget {
  final EnvelopeData envelope;
  final double size;

  const EnvelopeRing({super.key, required this.envelope, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final color = envelope.category?.color ?? AppColors.amber;
    final frac = envelope.fraction.clamp(0.0, 1.0);
    final isOver = envelope.fraction > 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: frac,
              strokeWidth: 5,
              backgroundColor: AppColors.bg4,
              valueColor: AlwaysStoppedAnimation(isOver ? AppColors.negative : color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(envelope.category?.icon ?? '📦', style: TextStyle(fontSize: size * 0.22)),
              Text(
                '${(envelope.fraction * 100).clamp(0, 999).toStringAsFixed(0)}%',
                style: AppText.caption.copyWith(fontSize: 9, color: AppColors.t2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Safe-to-spend headline card for the dashboard.
class SafeToSpendCard extends StatelessWidget {
  final double safeToSpend;
  final double todayTotal;
  final double monthlyRemaining;

  const SafeToSpendCard({
    super.key,
    required this.safeToSpend,
    required this.todayTotal,
    required this.monthlyRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = safeToSpend < 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative ambient glow
          Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.amber.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAFE TO SPEND TODAY',
                    style: AppText.label.copyWith(color: AppColors.t3),
                  ),
                  const SizedBox(height: 10),
                  AnimatedCurrency(
                    value: safeToSpend.abs(),
                    style: AppText.numberLarge(
                      color: isNegative ? AppColors.negative : AppColors.amber,
                    ).copyWith(fontSize: 36),
                    prefix: isNegative ? '-$currentCurrencySymbol' : currentCurrencySymbol,
                    delay: const Duration(milliseconds: 150),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 0.5,
            color: AppColors.line.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Today',
                  value: formatCurrency(todayTotal),
                  valueColor: AppColors.t1,
                ),
              ),
              Container(width: 0.5, height: 32, color: AppColors.line.withValues(alpha: 0.4)),
              Expanded(
                child: _StatCell(
                  label: 'Month left',
                  value: formatCurrency(monthlyRemaining),
                  valueColor: monthlyRemaining < 0 ? AppColors.negative : AppColors.t1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCell({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label.copyWith(color: AppColors.t3, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: AppText.numberSmall(color: valueColor).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Standard transaction row for lists.
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final List<TagModel> tags;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.tags = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.amber.withValues(alpha: 0.06),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Category icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bg4,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bg5),
                ),
                alignment: Alignment.center,
                child: Text(category?.icon ?? '📝', style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.note.isEmpty ? (category?.name ?? 'Expense') : transaction.note,
                      style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (category != null)
                          Text(
                            category!.name,
                            style: AppText.caption.copyWith(
                              color: category!.color.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ...tags.take(2).map((t) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: TagBadge(tag: t),
                            )),
                        const Spacer(),
                        Text(
                          DateFormat('HH:mm').format(transaction.date),
                          style: AppText.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '−${formatCurrency(transaction.amount)}',
                style: AppText.numberSmall(color: AppColors.t1).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty-state placeholder used across list screens.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppText.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Icon in a rounded square container — used in settings/list tiles.
class IconContainer extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const IconContainer({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bg3,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: iconColor ?? AppColors.amber),
    );
  }
}
