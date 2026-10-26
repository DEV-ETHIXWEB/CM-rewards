import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../state/rewards_state.dart';
import 'brand.dart';
import 'motion.dart';
import 'cm_icons.dart';

/// Space taken by the floating bottom navigation, or just the safe area when
/// the side rail is showing instead.
double navClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + (context.isExpandedWidth ? 16 : 104);

/// Bottom padding for scrolling pages so the last item clears the navigation.
double bottomInset(BuildContext context) => navClearance(context) + 16;

void showToast(BuildContext context, String message, {CMGlyph icon = CMGlyph.checkCircle}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CMIcon(icon, color: Brand.greenBright, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<void> launchExternal(BuildContext context, Uri uri, String failure) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    opened = false;
  }
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(failure)));
}

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.standard);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween<double>(begin: 1.03, end: 1).animate(curved), child: child),
      );
    },
  );
}

Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));

/// A bottom sheet on the page background, scrolling when tall.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder, {bool scroll = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: context.cm.background,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92, maxWidth: Breakpoints.sheet),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    // Full width, so a sheet of chips is as wide as one with a button.
    builder: (context) => SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        child: scroll
            ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), child: builder(context))
            : builder(context),
      ),
    ),
  );
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

enum ButtonTone { primary, positive, light, dark }

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.tone = ButtonTone.primary,
    this.trailing,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final CMGlyph? icon;
  final bool loading;
  final ButtonTone tone;
  final Widget? trailing;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  final _guard = TapGuard();

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final onPressed = widget.onPressed;
    final (bg, fg) = switch (widget.tone) {
      ButtonTone.primary => (c.primary, Brand.white),
      ButtonTone.positive => (c.positive, Brand.white),
      ButtonTone.light => (Brand.white, Brand.burgundy),
      ButtonTone.dark => (c.isDark ? Brand.ivory : Brand.ink, c.isDark ? Brand.ink : Brand.white),
    };
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: FilledButton(
        onPressed: widget.loading
            ? () {}
            : onPressed == null
            ? null
            : () {
                if (!_guard.allow()) return;
                RewardsScope.read(context).haptic();
                onPressed();
              },
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: c.faint,
          disabledForegroundColor: c.hint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.height / 2)),
          textStyle: const TextStyle(fontFamily: AppText.sans, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: AnimatedSwitcher(
          duration: Motion.medium,
          child: widget.loading
              ? MarketDots(key: const ValueKey('loading'), color: fg, size: 7)
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: widget.trailing == null ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    if (widget.icon case final icon?) ...[CMIcon(icon, size: 22), const SizedBox(width: 10)],
                    if (widget.trailing == null)
                      Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis))
                    else ...[
                      Expanded(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
                      widget.trailing!,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 50,
  });

  final String label;
  final CMGlyph icon;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return SizedBox(
      height: height,
      child: FilledButton.tonalIcon(
        onPressed: () {
          RewardsScope.read(context).haptic();
          onPressed();
        },
        style: FilledButton.styleFrom(
          backgroundColor: c.primarySoft,
          foregroundColor: c.primaryInk,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height / 2)),
          textStyle: const TextStyle(fontFamily: AppText.sans, fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
        icon: CMIcon(icon, size: 19),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// A round icon button on a surface, used in headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
    this.badge = 0,
    this.size = 46,
    this.background,
    this.foreground,
  });

  final CMGlyph icon;
  final VoidCallback onTap;
  final String label;
  final int badge;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      semanticLabel: badge > 0 ? '$label, $badge unread' : label,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? c.surface,
          shape: BoxShape.circle,
          border: Border.all(color: c.line),
        ),
        child: Center(
          child: Badge(
            label: ExcludeSemantics(child: Text('$badge')),
            isLabelVisible: badge > 0,
            backgroundColor: c.primary,
            textColor: Brand.white,
            child: CMIcon(icon, color: foreground ?? c.ink, size: size * 0.46),
          ),
        ),
      ),
    );
  }
}

// ─── Surfaces ─────────────────────────────────────────────────────────────────

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 26, this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: c.isDark ? Border.all(color: c.line) : null,
        boxShadow: c.elevation(),
      ),
      child: child,
    );
  }
}

/// A rounded square holding an icon or emoji on a tinted background.
class IconTile extends StatelessWidget {
  const IconTile({super.key, this.icon, this.emoji, this.color, this.background, this.size = 44, this.radius});

  final CMGlyph? icon;
  final String? emoji;
  final Color? color;
  final Color? background;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? c.primarySoft,
        borderRadius: BorderRadius.circular(radius ?? size * 0.32),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.46))
          : CMIcon(icon ?? CMGlyph.star, color: color ?? c.primaryInk, size: size * 0.48),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppText.eyebrow.copyWith(color: color ?? context.cm.muted));
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.actionNavigates = true,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  /// Shows a chevron only when the action opens another screen.
  final bool actionNavigates;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(color: c.muted, fontSize: 13.5)),
              ],
            ],
          ),
        ),
        ?trailing,
        if (actionLabel != null)
          Pressable(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(color: c.primaryInk, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (actionNavigates) CMIcon(CMGlyph.arrowRight, color: c.primaryInk, size: 17),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A horizontally scrolling row of choice chips.
class ChipFilter<T> extends StatelessWidget {
  const ChipFilter({super.key, required this.options, required this.selected, required this.onSelected, this.padding});

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return EdgeFade(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: padding,
        child: Row(
          children: [
            for (final (i, (value, label)) in options.indexed)
              Padding(
                padding: EdgeInsets.only(right: i == options.length - 1 ? 0 : 8),
                child: Pressable(
                  semanticLabel: label,
                  onTap: () => onSelected(value),
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    curve: Motion.standard,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: value == selected ? (c.isDark ? Brand.ivory : Brand.ink) : c.surface,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: value == selected ? Colors.transparent : c.line),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: Motion.medium,
                      style: TextStyle(
                        fontFamily: AppText.sans,
                        color: value == selected ? (c.isDark ? Brand.ink : Brand.white) : c.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      child: ExcludeSemantics(child: Text(label)),
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

/// A pill-shaped segmented control with a sliding thumb.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(23)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.medium,
                curve: Motion.standard,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: c.elevation(1.4),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i == index) return;
                            RewardsScope.read(context).haptic();
                            onChanged(i);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.medium,
                              style: TextStyle(
                                fontFamily: AppText.sans,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: i == index ? c.ink : c.muted,
                              ),
                              child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.positive, this.dot = true});

  final String label;
  final bool positive;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final color = positive ? c.positiveInk : c.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? c.positiveSoft : c.faint,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class PointsBadge extends StatelessWidget {
  const PointsBadge(this.points, {super.key, this.onDark = false});

  final int points;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Brand.white.withValues(alpha: 0.16) : c.positiveSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+$points pts',
        style: TextStyle(
          color: onDark ? Brand.white : c.positiveInk,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          fontFeatures: AppText.tabular,
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.track, this.height = 8});

  final double value;
  final Color? color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1200),
        curve: Motion.standard,
        builder: (context, v, child) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: track ?? c.faint,
          valueColor: AlwaysStoppedAnimation(color ?? c.positive),
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.compact = false});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final size = compact ? 32.0 : 44.0;
    Widget button(CMGlyph icon, String label, int next, bool enabled) => Pressable(
      semanticLabel: label,
      onTap: enabled ? () => onChanged(next) : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: enabled ? c.surface : c.faint, shape: BoxShape.circle),
        child: CMIcon(icon, size: size * 0.5, color: enabled ? c.ink : c.hint),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(size)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(value - 1 <= min && min == 0 ? CMGlyph.trash : CMGlyph.minus, 'Decrease', value - 1, value > min),
          SizedBox(
            width: compact ? 28 : 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 14 : 17, fontFeatures: AppText.tabular),
            ),
          ),
          button(CMGlyph.plus, 'Increase', value + 1, true),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  final CMGlyph icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                OrbitArcs(opacity: c.isDark ? 0.35 : 0.22),
                CMIcon(icon, size: 34, color: c.primaryInk),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: AppText.title),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// A grouped list of rows, like iOS settings, on a single panel.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Padding(padding: const EdgeInsets.fromLTRB(6, 0, 6, 10), child: Eyebrow(title!)),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 64, endIndent: 16, color: c.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackground,
    this.destructive = false,
  });

  final CMGlyph icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackground;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final tap = onTap;
    // Own Material so the ripple paints above the panel.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        minVerticalPadding: 12,
        onTap: tap == null
            ? null
            : () {
                RewardsScope.read(context).haptic();
                tap();
              },
        leading: IconTile(
          icon: icon,
          size: 38,
          color: destructive ? c.danger : iconColor,
          background: destructive ? c.danger.withValues(alpha: 0.1) : iconBackground,
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: destructive ? c.danger : c.ink),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: c.muted, fontSize: 12.5)),
        trailing: trailing ?? (tap == null ? null : CMIcon(CMGlyph.chevronRight, color: c.hint)),
      ),
    );
  }
}

/// A dashed tear line with notches, so a card reads as a ticket.
class TicketDivider extends StatelessWidget {
  const TicketDivider({super.key, required this.notchColor});

  final Color notchColor;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(count, (_) => Container(width: 5, height: 1.5, color: c.line)),
                );
              },
            ),
          ),
          Positioned(left: -11, child: _notch()),
          Positioned(right: -11, child: _notch()),
        ],
      ),
    );
  }

  Widget _notch() => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(color: notchColor, shape: BoxShape.circle),
  );
}

/// Starts a [Future] without awaiting it, for fire-and-forget navigation.
void fireAndForget(Future<void> future) => unawaited(future);
