import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../providers/data_providers.dart';

export '../../core/utils/formatters.dart';

/// NTIZA mark (an "N" with a sprouting leaf), drawn from an SVG asset.
/// [light] picks the white tile for use on dark green backgrounds.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 36, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        light ? 'assets/images/ntiza_mark_white.svg' : 'assets/images/ntiza_mark.svg',
        width: size,
        height: size,
        semanticsLabel: 'NTIZA logo',
      );
}

/// Logo + wordmark + tagline.
class LogoLockup extends StatelessWidget {
  const LogoLockup({super.key, this.light = false, this.size = 36});
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoMark(size: size, light: light),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NTIZA',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: light ? Colors.white : AppColors.ink)),
              Text('Digital Agriculture Platform',
                  style: TextStyle(fontSize: 11.5, color: light ? Colors.white : AppColors.muted)),
            ],
          ),
        ],
      );
}

/// Local asset image with a neutral fallback.
class AssetPhoto extends StatelessWidget {
  const AssetPhoto(this.name, {super.key, this.height, this.width, this.radius = 0});
  final String name;
  final double? height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: name.isEmpty
            ? Container(height: height, width: width, color: AppColors.neutral)
            : name.startsWith('http')
                ? Image.network(
                    name,
                    height: height,
                    width: width ?? double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: height, width: width, color: AppColors.neutral),
                  )
                : Image.asset(
                    'assets/images/$name',
                    height: height,
                    width: width ?? double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: height, width: width, color: AppColors.neutral),
                  ),
      );
}

/// Duration that collapses to zero when the user turned animations off.
Duration motion(BuildContext context, [Duration d = const Duration(milliseconds: 200)]) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

/// Shrinks its child slightly while a finger is down. Uses a raw pointer
/// listener so it never competes with the child's own tap handling.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: motion(context, const Duration(milliseconds: 110)),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Fades and lifts its child in once, after an optional [index]-based delay
/// (capped, so long lists do not feel slow).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 45 * (index > 6 ? 6 : index));
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380) + delay,
      curve: Interval(delay.inMilliseconds / (380 + delay.inMilliseconds), 1,
          curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

/// White rounded card with a soft shadow. A visible outline is drawn only when
/// [borderColor] is given (selected states).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.onTap,
    this.borderColor = Colors.transparent,
    this.radius = AppRadius.card,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Pressable(
      enabled: onTap != null,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: shape,
          border: borderColor == Colors.transparent ? null : Border.all(color: borderColor),
          boxShadow: AppShadow.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label,
      {super.key, this.bg = AppColors.green100, this.fg = AppColors.primaryDark, this.big = false});
  final String label;
  final Color bg;
  final Color fg;
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: big ? 14 : 11, vertical: big ? 7 : 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(label,
            style: TextStyle(color: fg, fontSize: big ? 13 : 12, fontWeight: FontWeight.w600)),
      );
}

/// Status chip mapped from a status keyword.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg = AppColors.neutral, fg = AppColors.body;
    if (s.startsWith('free') ||
        ['available', 'completed', 'paid', 'active', 'approved', 'verified', 'online']
            .contains(s)) {
      bg = AppColors.green100;
      fg = AppColors.primaryDark;
    } else if (['confirmed', 'in progress', 'info', 'open'].contains(s)) {
      bg = AppColors.blueBg;
      fg = AppColors.blue;
    } else if (['pending', 'booked', 'review', 'maintenance', 'in maintenance', 'under review']
        .contains(s)) {
      bg = AppColors.amberBg;
      fg = AppColors.amberText;
    } else if (s == 'expert') {
      bg = AppColors.purpleBg;
      fg = AppColors.purple;
    } else if (['cancelled', 'rejected', 'suspended', 'disputed', 'overdue', 'fully booked']
        .contains(s)) {
      bg = AppColors.dangerBg;
      fg = AppColors.danger;
    }
    return Pill(status, bg: bg, fg: fg);
  }
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon,
      {super.key,
      this.bg = AppColors.green100,
      this.fg = AppColors.primaryDark,
      this.size = 52,
      this.radius = 16});
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, color: fg, size: size * 0.46),
      );
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials,
      {super.key, this.size = 52, this.bg = AppColors.green100, this.fg = AppColors.primaryDark});
  final String initials;
  final double size;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(initials,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.3)),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label,
      {super.key, this.onPressed, this.height = 50, this.icon, this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(expand ? double.infinity : 0, height < 48 ? 48 : height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    return Pressable(
        enabled: onPressed != null,
        child: expand ? SizedBox(width: double.infinity, child: btn) : btn);
  }
}

class OutlineButtonX extends StatelessWidget {
  const OutlineButtonX(this.label,
      {super.key, this.onPressed, this.height = 50, this.expand = true, this.color});
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;
  final Color? color;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color ?? AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          minimumSize: Size(expand ? double.infinity : 0, height < 48 ? 48 : height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      );
}

/// Small green-tinted action button ("Book", "Approve" …).
class SoftButton extends StatelessWidget {
  const SoftButton(this.label,
      {super.key, this.onPressed, this.bg = AppColors.green100, this.fg = AppColors.primaryDark});
  final String label;
  final VoidCallback? onPressed;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ),
      );
}

/// Round white icon button with a soft shadow; optional unread dot.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton(
      {super.key, required this.icon, this.onTap, this.size = 42, this.dot = false, this.label});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool dot;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Pressable(
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle, boxShadow: AppShadow.card),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: AppColors.ink, size: size * 0.52),
                    if (dot)
                      Positioned(
                        right: size * 0.26,
                        top: size * 0.24,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Page-coloured app bar: no outline, left-aligned title, small round back
/// button. Tab screens pass `back: false`.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar(this.title, {super.key, this.back = true, this.bell = false, this.actions});
  final String title;
  final bool back;
  final bool bell;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (back) ...[
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Back',
                    onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                ...?actions,
                if (bell) const BellButton(),
              ],
            ),
          ),
        ),
      );
}

/// Notification bell with an unread dot, opening the notification list.
class BellButton extends ConsumerWidget {
  const BellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CircleIconButton(
        icon: Icons.notifications_none_rounded,
        label: 'Notifications',
        dot: ref.watch(unreadCountProvider) > 0,
        onTap: () => context.push('/notifications'),
      );
}

/// Bare bell glyph (used on photos, where [light] makes it white).
class BellIcon extends ConsumerWidget {
  const BellIcon({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none, size: 26, color: light ? Colors.white : AppColors.ink),
          if (unread > 0)
            Positioned(
              right: 2,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
        ],
      );
}

/// Horizontal scrolling pill filter (compact: 36dp chips).
class ChipRow extends StatelessWidget {
  const ChipRow(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onSelected,
      this.padding = const EdgeInsets.symmetric(horizontal: 16)});
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final on = labels[i] == selected;
            return Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(labels[i]),
                child: ConstrainedBox(
                  // Keeps the 44dp touch target even though the chip is 36dp.
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    child: AnimatedContainer(
                      duration: motion(context, const Duration(milliseconds: 160)),
                      curve: Curves.easeOut,
                      height: 36,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: on ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: on ? null : AppShadow.card,
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: motion(context, const Duration(milliseconds: 160)),
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: on ? Colors.white : AppColors.ink),
                        child: Text(labels[i]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

/// Round icon tiles with a caption underneath (equipment types, categories).
class CategoryTiles extends StatelessWidget {
  const CategoryTiles(
      {super.key, required this.items, required this.selected, required this.onSelected});
  final List<(String, IconData)> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 94,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final (label, icon) = items[i];
            final on = label == selected;
            return Semantics(
              button: true,
              selected: on,
              label: label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(label),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: motion(context, const Duration(milliseconds: 180)),
                        curve: Curves.easeOut,
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: on ? AppColors.primary : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: on ? AppShadow.floating : AppShadow.card,
                        ),
                        child:
                            Icon(icon, size: 26, color: on ? Colors.white : AppColors.primaryDark),
                      ),
                      const SizedBox(height: 6),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                              color: on ? AppColors.primaryDark : AppColors.body)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

/// One borderless, filled search pill. Pass [onFilter] to show a green filter
/// button inside it; pass [onTap] to make it a button that opens a search page.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, this.onChanged, this.onFilter, this.onTap});
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: EdgeInsets.fromLTRB(16, 0, onFilter == null ? 16 : 6, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                onTap: onTap,
                readOnly: onTap != null,
                style: const TextStyle(fontSize: 15),
                // Every border is switched off explicitly: the app theme gives
                // inputs an outline, which would draw a box inside this pill.
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ).copyWith(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.faint),
                ),
              ),
            ),
            if (onFilter != null)
              Semantics(
                button: true,
                label: 'Filters',
                child: GestureDetector(
                  onTap: onFilter,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration:
                        const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Centered empty state: tinted icon circle, title, optional hint and action.
class EmptyState extends StatelessWidget {
  const EmptyState(this.title,
      {super.key,
      this.message,
      this.icon = Icons.inbox_outlined,
      this.actionLabel,
      this.onAction,
      this.padding = 40});
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: 24),
        child: Center(
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration:
                      const BoxDecoration(color: AppColors.green100, shape: BoxShape.circle),
                  child: Icon(icon, size: 34, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (message != null) ...[
                  const SizedBox(height: 6),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted)),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(actionLabel!, expand: false, height: 46, onPressed: onAction),
                ],
              ],
            ),
          ),
        ),
      );
}

/// Pulsing grey placeholder card shown while a list loads.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 3, this.height = 150});
  final int count;
  final double height;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final box = Column(
      children: [
        for (var i = 0; i < widget.count; i++) ...[
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.green100.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
    return Semantics(
      label: 'Loading',
      child: still
          ? box
          : FadeTransition(
              opacity: Tween(begin: 0.45, end: 1.0)
                  .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
              child: box,
            ),
    );
  }
}

class RatingLine extends StatelessWidget {
  const RatingLine(this.rating, this.suffix, {super.key});
  final double rating;
  final String suffix;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: AppColors.amber),
          const SizedBox(width: 4),
          Text('${rating.toStringAsFixed(1)} · $suffix',
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
        ],
      );
}

class StatTile extends StatelessWidget {
  const StatTile(this.value, this.label,
      {super.key, this.icon, this.bg = AppColors.green100, this.fg = AppColors.primaryDark});
  final String value;
  final String label;
  final IconData? icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(height: 8)],
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12.5, color: fg)),
          ],
        ),
      );
}

/// Labelled text field used by auth/forms.
/// Whether a password field currently hides its text (keyed by field label).
final _hidePasswordProvider = StateProvider.autoDispose.family<bool, String>((ref, label) => true);

/// A labelled text input with inline validation. Use inside a `Form` and call
/// `formKey.currentState!.validate()` to show every error at once.
class LabeledField extends ConsumerWidget {
  const LabeledField(this.label,
      {super.key,
      required this.hint,
      this.icon,
      this.obscure = false,
      this.controller,
      this.keyboard,
      this.validator,
      this.textInputAction,
      this.autofillHints,
      this.maxLines = 1,
      this.enabled = true,
      this.onChanged,
      this.onSubmitted});
  final String label;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = obscure && ref.watch(_hidePasswordProvider(label));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.body)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: hidden,
          keyboardType: keyboard,
          validator: validator,
          enabled: enabled,
          maxLines: obscure ? 1 : maxLines,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.faint),
            prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
            suffixIcon: obscure
                ? IconButton(
                    tooltip: hidden ? 'Show password' : 'Hide password',
                    icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted),
                    onPressed: () =>
                        ref.read(_hidePasswordProvider(label).notifier).state = !hidden,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
