import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/avatar.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'account.dart';
import 'activity.dart';
import 'notifications.dart';
import 'order.dart';
import 'pass.dart';
import 'sheets.dart';
import 'shell.dart';
import 'stores.dart';
import '../widgets/cm_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<AppTab> onNavigate;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Up late';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _refresh(BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!context.mounted) return;
    showToast(context, "You're all caught up", icon: CMGlyph.refresh);
  }

  Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

  @override
  Widget build(BuildContext context) {
    final state = RewardsScope.of(context);
    final c = context.cm;
    final recent = state.transactions.take(3).toList();
    final forYou = state.personalizedOffers
        ? ([...deals]..sort((a, b) => (b.forYou ? 1 : 0) - (a.forYou ? 1 : 0)))
        : deals;
    final popular = menu.where((m) => m.popular).toList();
    final order = state.activeOrder;
    final rail = context.isExpandedWidth;

    final header = _pad(
      Row(
        children: [
          // The side rail already shows the logo and account on wide screens.
          if (!rail) const CMLogo(height: 38),
          const Spacer(),
          CircleIconButton(
            icon: CMGlyph.bell,
            label: 'Notifications',
            badge: state.unreadCount,
            onTap: () => push<void>(context, const NotificationsScreen()),
          ),
          if (!rail) ...[
            const SizedBox(width: 10),
            Pressable(
              semanticLabel: 'Account',
              onTap: () => push<void>(context, const AccountScreen()),
              child: Avatar(size: 46),
            ),
          ],
        ],
      ),
    );
    final greeting = _pad(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.firstName.isEmpty ? _greeting() : '${_greeting()},',
            style: TextStyle(fontSize: 15, color: c.muted, fontWeight: FontWeight.w600),
          ),
          Text(state.firstName.isEmpty ? 'Welcome' : state.firstName, style: AppText.display),
        ],
      ),
    );

    Widget carousel({required double height, required int count, required IndexedWidgetBuilder item}) => EdgeFade(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: count,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: item,
        ),
      ),
    );

    // The member's own things: points, today's nudge, streak and store.
    final mine = [
      // A live order is the most time-sensitive thing, so it goes first.
      if (order != null) ...[reveal(2, _pad(ActiveOrderBanner(order: order))), const SizedBox(height: 14)],
      reveal(2, _pad(MemberCard(onTap: () => showMemberPass(context)))),
      const SizedBox(height: 14),
      reveal(3, _pad(_MomentCard(onOrder: () => onNavigate(AppTab.order)))),
      const SizedBox(height: 22),
      reveal(3, _pad(_QuickActions(onNavigate: onNavigate))),
      const SizedBox(height: 28),
      reveal(4, _pad(const _StreakCard())),
      const SizedBox(height: 28),
      reveal(4, _pad(SectionHeader('Your store', actionLabel: 'Change', onAction: () => onNavigate(AppTab.stores)))),
      const SizedBox(height: 12),
      reveal(4, _pad(HomeStoreCard(onOrder: () => onNavigate(AppTab.order)))),
    ];

    // What's on offer this week.
    final offers = [
      reveal(
        5,
        _pad(
          SectionHeader(
            state.personalizedOffers ? 'Picked for you' : "This week's offers",
            subtitle: state.clippedDeals.isEmpty
                ? 'Clip offers and they apply when you scan'
                : '${state.clippedDeals.length} clipped · applied at your next scan',
          ),
        ),
      ),
      const SizedBox(height: 14),
      reveal(
        5,
        carousel(
          height: context.textHeight(252, textShare: 0.4),
          count: forYou.length,
          item: (context, index) =>
              DealCard(deal: forYou[index], clipped: state.clippedDeals.contains(forYou[index].id)),
        ),
      ),
      const SizedBox(height: 28),
      reveal(6, _pad(const SectionHeader('Bonus challenges', subtitle: 'Extra points, just for showing up'))),
      const SizedBox(height: 14),
      reveal(
        6,
        carousel(
          height: context.textHeight(156, textShare: 0.7),
          count: challenges.length,
          item: (context, index) => ChallengeCard(challenge: challenges[index]),
        ),
      ),
      const SizedBox(height: 28),
      reveal(
        7,
        _pad(SectionHeader('Popular to order', actionLabel: 'Full menu', onAction: () => onNavigate(AppTab.order))),
      ),
      const SizedBox(height: 14),
      reveal(
        7,
        carousel(
          height: context.textHeight(196, textShare: 0.35),
          count: popular.length,
          item: (context, index) => _PopularTile(item: popular[index]),
        ),
      ),
    ];

    final story = reveal(8, _pad(StoryVideoCard(onFindStore: () => onNavigate(AppTab.stores))));
    final activity = [
      reveal(
        8,
        _pad(
          SectionHeader(
            'Recent activity',
            actionLabel: 'See all',
            onAction: () => push<void>(context, const ActivityScreen()),
          ),
        ),
      ),
      const SizedBox(height: 12),
      reveal(
        8,
        _pad(
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 72, endIndent: 16, color: c.line),
                  TransactionTile(transaction: recent[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    ];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: () => _refresh(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Wide windows get a dashboard: the member's things on the left,
            // offers and the store story on the right.
            final columns = constraints.maxWidth >= Breakpoints.wideHome;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.only(top: 10, bottom: bottomInset(context)),
              children: [
                reveal(0, header),
                const SizedBox(height: 22),
                reveal(1, greeting),
                const SizedBox(height: 18),
                if (!columns) ...[
                  ...mine,
                  const SizedBox(height: 28),
                  ...offers,
                  const SizedBox(height: 28),
                  story,
                  const SizedBox(height: 28),
                  ...activity,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth * 0.4).clamp(380, 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...mine, const SizedBox(height: 28), ...activity],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...offers, const SizedBox(height: 28), story],
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Member card ──────────────────────────────────────────────────────────────

class MemberCard extends StatelessWidget {
  const MemberCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final state = RewardsScope.of(context);
    final next = state.nextReward;
    final remaining = max(0, next.points - state.points);

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      semanticLabel: 'Member card, ${formatNumber(state.points)} points. Tap to scan.',
      child: BurgundySurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Eyebrow('CM Rewards', color: Brand.white.withValues(alpha: 0.75))),
                  const SizedBox(width: 8),
                  TierChip(tier: state.tier),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedCount(
                value: state.points,
                from: 0,
                builder: (context, value) => Text.rich(
                  TextSpan(
                    text: formatNumber(value),
                    style: AppText.hero.copyWith(fontSize: 52, fontFeatures: AppText.tabular),
                    children: const [
                      TextSpan(
                        text: '  points',
                        style: TextStyle(fontFamily: AppText.sans, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: const TextStyle(color: Brand.white),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(next.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remaining > 0 ? '${formatNumber(remaining)} pts to ${next.name}' : 'You can redeem ${next.name}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Brand.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ProgressBar(
                value: state.points / next.points,
                color: Brand.greenBright,
                track: Brand.white.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        state.memberId,
                        style: TextStyle(
                          color: Brand.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Brand.white, borderRadius: BorderRadius.circular(Radii.md)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CMIcon(CMGlyph.qr, size: 17, color: Brand.burgundy),
                        SizedBox(width: 6),
                        Text(
                          'Scan to earn',
                          style: TextStyle(color: Brand.burgundy, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TierChip extends StatelessWidget {
  const TierChip({super.key, required this.tier, this.onDark = true});

  final Tier tier;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final insider = tier == Tier.insider;
    final c = context.cm;
    // On a light or dark surface, use the theme's readable ink for the tier's color.
    final ink = switch (tier) {
      Tier.neighbor => c.positiveInk,
      Tier.regular => c.primaryInk,
      Tier.insider => c.accentInk,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: insider ? const LinearGradient(colors: [Brand.champagne, Color(0xFFF6E3BC)]) : null,
        color: insider ? null : (onDark ? Brand.white.withValues(alpha: 0.16) : ink.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CMIcon(CMGlyph.medal, size: 15, color: insider ? Brand.burgundyDeep : (onDark ? Brand.white : ink)),
          const SizedBox(width: 4),
          Text(
            tier.label,
            style: TextStyle(
              color: insider ? Brand.burgundyDeep : (onDark ? Brand.white : ink),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      scale: 0.98,
      onTap: () => push<void>(context, OrderTrackerScreen(order: order)),
      child: TickBuilder(
        builder: (context) {
          final now = DateTime.now();
          final stage = order.stageAt(now);
          final ready = stage == OrderStage.ready;
          return Panel(
            padding: const EdgeInsets.all(14),
            color: ready ? c.positiveSoft : null,
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: order.progressAt(now),
                        strokeWidth: 3.5,
                        backgroundColor: c.faint,
                        color: c.positive,
                        strokeCap: StrokeCap.round,
                      ),
                      CMIcon(stage.icon, size: 20, color: ready ? c.positiveInk : c.primaryInk),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.number} · ${stage.title}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ready
                            ? 'At ${storeByNumber(order.storeNumber).name}'
                            : 'Ready in about ${formatCountdown(order.readyAt.difference(now))}',
                        style: TextStyle(color: c.muted, fontSize: 13, fontFeatures: AppText.tabular),
                      ),
                    ],
                  ),
                ),
                CMIcon(CMGlyph.chevronRight, color: c.hint),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A time-of-day nudge, the kind of thing a real member app learns to say.
class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final hour = DateTime.now().hour;
    final (emoji, title, body) = switch (hour) {
      < 10 => ('☕', 'Coffee earns 2× before 10 AM', 'Skip the line: order ahead and it’s waiting at the counter.'),
      < 14 => ('🍗', 'Lunch is hot and ready', 'Tenders basket, jojos and a drink. Order ahead in seconds.'),
      < 18 => ('🧊', 'Afternoon pick-me-up', 'Any size Icee is \$1.49 today. Clip it and it applies at checkout.'),
      _ => ('🍕', 'Pizza night, sorted', 'Grab a whole 16" for the crew. Ready in about 15 minutes.'),
    };
    return Pressable(
      scale: 0.98,
      onTap: onOrder,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.positiveSoft, borderRadius: BorderRadius.circular(Radii.md)),
        child: Row(
          children: [
            IconTile(emoji: emoji, background: c.surface, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.positiveInk),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(fontSize: 13, color: c.ink.withValues(alpha: 0.75), height: 1.35)),
                ],
              ),
            ),
            CMIcon(CMGlyph.arrowRight, color: c.positiveInk, size: 20),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<AppTab> onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final actions = [
      (CMGlyph.bagFill, 'Order\nahead', c.primaryInk, c.primarySoft, () => onNavigate(AppTab.order)),
      (CMGlyph.fuel, 'Fuel\nprices', c.positiveInk, c.positiveSoft, () => showFuelSheet(context)),
      (CMGlyph.handHeart, 'Gift\npoints', c.primaryInk, c.primarySoft, () => showGiftSheet(context)),
      (CMGlyph.people, 'Refer &\nearn', c.positiveInk, c.positiveSoft, () => showReferralSheet(context)),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: actions[i].$5,
              semanticLabel: actions[i].$2.replaceAll('\n', ' '),
              child: Panel(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon: actions[i].$1, color: actions[i].$3, background: actions[i].$4, size: 38),
                    const SizedBox(height: 12),
                    // Shrinks rather than breaking a word when text is very large.
                    ExcludeSemantics(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          actions[i].$2,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final days = state.visitDaysThisWeek;
    final today = DateTime.now().weekday - 1;
    final weeks = state.streakWeeks;
    final visitsLeft = max(0, 3 - days.length);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weeks > 0 ? '$weeks-week streak' : 'Start a streak',
                      style: AppText.headline.copyWith(fontSize: 21),
                    ),
                    Text(
                      visitsLeft == 0
                          ? 'Weekly bonus unlocked. Nice!'
                          : '$visitsLeft more ${visitsLeft == 1 ? 'visit' : 'visits'} this week for +${challenges.first.reward} pts',
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    AnimatedContainer(
                      duration: Motion.medium,
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: days.contains(i) ? c.positive : (i == today ? c.primarySoft : c.faint),
                        border: i == today ? Border.all(color: c.primaryInk, width: 1.6) : null,
                      ),
                      child: days.contains(i) ? const CMIcon(CMGlyph.check, size: 18, color: Brand.white) : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weekdays[i].substring(0, 1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == today ? FontWeight.w800 : FontWeight.w600,
                        color: i == today ? c.ink : c.muted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeStoreCard extends StatelessWidget {
  const HomeStoreCard({super.key, required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final store = state.home;
    final now = DateTime.now();
    final open = store.isOpenAt(now);
    final fuel = store.fuel;

    return Pressable(
      scale: 0.98,
      onTap: () => showStoreSheet(context, store),
      child: Panel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: BrandPhoto(store.photo, semanticLabel: '${store.name} storefront'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        '${store.address} · ${store.distanceLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusPill(label: store.hoursLabel(now), positive: open),
                          if (open) StatusPill(label: store.busyLabel(now), positive: false, dot: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (fuel != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(Radii.sm)),
                child: Row(
                  children: [
                    CMIcon(CMGlyph.fuel, size: 18, color: c.positiveInk),
                    const SizedBox(width: 8),
                    Text('Regular ', style: TextStyle(color: c.muted, fontSize: 13)),
                    Text(
                      formatFuel(fuel.regular - state.tier.fuelDiscountCents * 10),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: AppText.tabular),
                    ),
                    const Spacer(),
                    if (state.tier.fuelDiscountCents > 0)
                      Text(
                        'Incl. your ${state.tier.fuelDiscountCents}¢ ${state.tier.label} discount',
                        style: TextStyle(color: c.positiveInk, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Directions',
                    icon: CMGlyph.navigate,
                    height: 44,
                    onPressed: () => openDirections(context, store),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(label: 'Order here', icon: CMGlyph.bag, height: 44, onPressed: onOrder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Offers & challenges ──────────────────────────────────────────────────────

class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.deal, required this.clipped, this.width = 186});

  final Deal deal;
  final bool clipped;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      onTap: () => showDealSheet(context, deal),
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: c.isDark ? Border.all(color: c.line) : null,
          boxShadow: c.elevation(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BrandPhoto(deal.photo, semanticLabel: deal.title),
                  const Scrim(from: 0.45, opacity: 0.55),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _Tag(text: deal.forYou ? 'For you' : deal.tag, highlight: deal.forYou),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    right: 12,
                    child: Text(
                      deal.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.headline.copyWith(color: Brand.white, fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(deal.endsIn, style: TextStyle(fontSize: 12.5, color: c.muted)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: deal.bonusPoints > 0
                                ? FittedBox(fit: BoxFit.scaleDown, child: PointsBadge(deal.bonusPoints))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ClipButton(deal: deal, clipped: clipped),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? Brand.green : Brand.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlight) ...[const CMIcon(CMGlyph.sparkle, size: 12, color: Brand.white), const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: highlight ? Brand.white : Brand.ink),
          ),
        ],
      ),
    );
  }
}

class ClipButton extends StatelessWidget {
  const ClipButton({super.key, required this.deal, required this.clipped});

  final Deal deal;
  final bool clipped;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      semanticLabel: clipped ? 'Unclip ${deal.title}' : 'Clip ${deal.title}',
      onTap: () {
        RewardsScope.read(context).toggleDeal(deal.id);
        if (!clipped) showToast(context, 'Clipped. It applies next time you scan.', icon: CMGlyph.clip);
      },
      child: AnimatedContainer(
        duration: Motion.medium,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: clipped ? c.positive : c.primarySoft, borderRadius: BorderRadius.circular(17)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Motion.medium,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: CMIcon(
                clipped ? CMGlyph.check : CMGlyph.plus,
                key: ValueKey(clipped),
                size: 17,
                color: clipped ? Brand.white : c.primaryInk,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              clipped ? 'Clipped' : 'Clip',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: clipped ? Brand.white : c.primaryInk),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDealSheet(BuildContext context, Deal deal) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final clipped = RewardsScope.of(context).clippedDeals.contains(deal.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg),
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BrandPhoto(deal.photo, semanticLabel: deal.title),
                const Scrim(from: 0.5, opacity: 0.6),
                Positioned(left: 14, top: 14, child: _Tag(text: deal.tag)),
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: Text(deal.price, style: AppText.hero.copyWith(color: Brand.white, fontSize: 36)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(deal.title, style: AppText.headline),
        const SizedBox(height: 8),
        Text(
          '${deal.description} Available at participating Center Market locations while supplies last.',
          style: TextStyle(color: c.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(label: deal.endsIn, positive: false, dot: false),
            if (deal.bonusPoints > 0) PointsBadge(deal.bonusPoints),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: clipped ? 'Clipped to your card' : 'Clip to my card',
          icon: clipped ? CMGlyph.checkCircle : CMGlyph.clip,
          tone: clipped ? ButtonTone.positive : ButtonTone.primary,
          onPressed: () => RewardsScope.read(context).toggleDeal(deal.id),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Clipped offers apply automatically when you scan your card.',
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
        ),
      ],
    );
  });
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final done = RewardsScope.of(context).challengeProgress(challenge);
    final progress = done / challenge.goal;
    return Container(
      width: 236,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: c.isDark ? Border.all(color: c.line) : null,
        boxShadow: c.elevation(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(emoji: challenge.emoji, size: 40, background: c.surfaceAlt),
              const Spacer(),
              PointsBadge(challenge.reward),
            ],
          ),
          const Spacer(),
          Text(
            challenge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ProgressBar(value: progress, height: 7),
          const SizedBox(height: 8),
          Text(
            '${challenge.prefix}$done of ${challenge.prefix}${challenge.goal}  ·  ${challenge.endsIn}',
            style: TextStyle(fontSize: 12, color: c.muted, fontFeatures: AppText.tabular),
          ),
        ],
      ),
    );
  }
}

class _PopularTile extends StatelessWidget {
  const _PopularTile({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      onTap: () => showMenuItemSheet(context, item),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: c.isDark ? Border.all(color: c.line) : null,
          boxShadow: c.elevation(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuThumb(item: item, height: 96),
            const SizedBox(height: 10),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(formatMoney(item.cents), style: TextStyle(color: c.muted, fontSize: 13)),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                  child: const CMIcon(CMGlyph.plus, size: 18, color: Brand.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StoryVideoCard extends StatelessWidget {
  const StoryVideoCard({super.key, required this.onFindStore});

  final VoidCallback onFindStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.xl), boxShadow: context.cm.elevation(2)),
      child: AspectRatio(
        aspectRatio: 4 / 3.5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const BrandVideo(),
            // Two layers: a soft wash over the whole film, and a deep fade where the text sits.
            ColoredBox(color: Brand.burgundyDeep.withValues(alpha: 0.18)),
            const Scrim(from: 0.05, opacity: 0.96, color: Brand.burgundyDeep),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Inside Center Market', color: Color(0xCCFFFFFF)),
                  const SizedBox(height: 8),
                  Text(
                    'Locally owned.\nCommunity focused.\nAlways convenient.',
                    style: AppText.display.copyWith(color: Brand.white, fontSize: 27, height: 1.1),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Pressable(
                        onTap: onFindStore,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(color: Brand.white, borderRadius: BorderRadius.circular(Radii.md)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CMIcon(CMGlyph.pin, size: 18, color: Brand.burgundy),
                              SizedBox(width: 6),
                              Text(
                                'Find a store',
                                style: TextStyle(fontWeight: FontWeight.w800, color: Brand.burgundy),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: () => showAboutSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: Brand.white.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'Our story',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Brand.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
