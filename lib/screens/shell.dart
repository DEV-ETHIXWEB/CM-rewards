import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'account.dart';
import 'home.dart';
import 'order.dart';
import 'pass.dart';
import 'rewards.dart';
import 'stores.dart';
import '../widgets/cm_icons.dart';

enum AppTab { home, order, rewards, stores }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  final _visited = <int>{0};
  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _switch, curve: Motion.standard);

  @override
  void dispose() {
    _switch.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
    _switch.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final pages = [
      HomeScreen(onNavigate: (tab) => _select(tab.index)),
      const OrderScreen(),
      const RewardsScreen(),
      const StoresScreen(),
    ];
    final topInset = MediaQuery.paddingOf(context).top;
    final expanded = context.isExpandedWidth;

    final content = Stack(
      children: [
        AnimatedBuilder(
          animation: _curve,
          builder: (context, child) => Opacity(
            opacity: _curve.value,
            child: Transform.translate(offset: Offset(0, 12 * (1 - _curve.value)), child: child),
          ),
          child: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < pages.length; i++)
                TickerMode(
                  enabled: i == _index,
                  child: _visited.contains(i)
                      ? ContentWidth(maxWidth: expanded ? Breakpoints.wide : Breakpoints.content, child: pages[i])
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
        // Content fades out under the status bar instead of being sliced off.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + 16,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.6, 1],
                  colors: [c.background, c.background.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // Android back on another tab returns Home first, then leaves the app.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          extendBody: true,
          // Wide windows (iPad landscape, large tablets) get a side rail; phones a floating bar.
          body: expanded
              ? Row(
                  children: [
                    _SideRail(index: _index, onSelect: _select),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: expanded
              ? null
              : Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    // Tab labels grow less than body text, like system tab bars.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.15,
                      child: _GlassNavBar(index: _index, onSelect: _select),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final padding = MediaQuery.paddingOf(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
        width: 112,
        padding: EdgeInsets.fromLTRB(0, padding.top + 20, 0, padding.bottom + 20),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(right: BorderSide(color: c.line)),
        ),
        child: Column(
          children: [
            const CMLogo(height: 34),
            const SizedBox(height: 28),
            const _ScanButton(),
            const SizedBox(height: 6),
            Text(
              'Scan',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.muted),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < _GlassNavBar._items.length; i++)
              _NavItem(index: i, selected: i == index, onTap: () => onSelect(i), vertical: true),
            const Spacer(),
            Pressable(
              semanticLabel: 'Account',
              onTap: () => push<void>(context, const AccountScreen()),
              child: Avatar(size: 48),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (CMGlyph.home, CMGlyph.homeFill, 'Home'),
    (CMGlyph.bag, CMGlyph.bagFill, 'Order'),
    (CMGlyph.gift, CMGlyph.giftFill, 'Rewards'),
    (CMGlyph.store, CMGlyph.storeFill, 'Stores'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    Widget item(int i) => Expanded(
      child: _NavItem(index: i, selected: i == index, onTap: () => onSelect(i)),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.xl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: c.isDark ? 0.72 : 0.82),
                      borderRadius: BorderRadius.circular(Radii.xl),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(children: [item(0), item(1), const SizedBox(width: 76), item(2), item(3)]),
                  ),
                ),
              ),
              const Positioned(top: -6, child: _ScanButton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton();

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      key: const ValueKey('nav-scan'),
      semanticLabel: 'Scan to earn',
      scale: 0.92,
      onTap: () => showMemberPass(context),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Brand.burgundyBright, Brand.burgundyDeep],
          ),
          border: Border.all(color: c.background, width: 4),
          boxShadow: [
            BoxShadow(color: Brand.burgundy.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: const CMIcon(CMGlyph.scan, color: Brand.white, size: 28),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.index, required this.selected, required this.onTap, this.vertical = false});

  final int index;
  final bool selected;
  final VoidCallback onTap;

  /// In the side rail, items stack with spacing instead of sharing a row.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final (icon, activeIcon, label) = _GlassNavBar._items[index];
    final showBadge = index == AppTab.order.index && state.cartCount > 0;
    return Pressable(
      key: ValueKey('nav-${label.toLowerCase()}'),
      semanticLabel: label,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: vertical ? 10 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.standard,
              width: selected ? 56 : 40,
              height: vertical ? 34 : 30,
              decoration: BoxDecoration(
                color: selected ? c.primarySoft : c.primarySoft.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Badge(
                isLabelVisible: showBadge,
                label: Text('${state.cartCount}'),
                backgroundColor: c.positive,
                offset: const Offset(6, -4),
                // A soft spring each time a tab becomes selected.
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(selected),
                  tween: Tween(begin: selected ? 0.72 : 1, end: 1),
                  duration: Motion.slow,
                  curve: Motion.spring,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: CMIcon(selected ? activeIcon : icon, size: 23, color: selected ? c.primaryInk : c.muted),
                ),
              ),
            ),
            const SizedBox(height: 3),
            ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c.primaryInk : c.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
