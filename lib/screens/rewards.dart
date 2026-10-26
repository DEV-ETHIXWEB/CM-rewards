import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/codes.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home.dart';
import 'sheets.dart';
import '../widgets/cm_icons.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _tab = 0;
  RewardCategory? _category;

  Future<void> _redeem(Reward reward) async {
    final state = RewardsScope.read(context);
    final confirmed = await showAppSheet<bool>(context, (context) {
      final c = context.cm;
      return Column(
        children: [
          RewardArt(reward: reward, size: 110),
          const SizedBox(height: 16),
          Text('Redeem ${reward.name}?', textAlign: TextAlign.center, style: AppText.headline),
          const SizedBox(height: 6),
          Text(
            reward.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 20),
          Panel(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow(c, 'Your balance', '${formatNumber(state.points)} pts'),
                const SizedBox(height: 8),
                _summaryRow(c, 'Reward cost', '-${formatNumber(reward.points)} pts', color: c.primaryInk),
                Divider(height: 24, color: c.line),
                _summaryRow(c, 'Balance after', '${formatNumber(state.points - reward.points)} pts', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Your code is valid for 15 minutes after redeeming.', style: TextStyle(fontSize: 12.5, color: c.muted)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Redeem for ${formatNumber(reward.points)} pts',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: c.muted),
            child: const Text('Not now'),
          ),
        ],
      );
    });
    if (confirmed != true || !mounted) return;
    final active = state.redeem(reward);
    if (active == null) return;
    state.haptic(strong: true);
    await showRewardTicket(context, active, celebrate: true);
  }

  Widget _summaryRow(CMColors c, String label, String value, {Color? color, bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: c.muted)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? c.ink,
            fontFeatures: AppText.tabular,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final wallet = state.wallet;
    final clipped = deals.where((d) => state.clippedDeals.contains(d.id)).toList();
    final walletCount = wallet.length + clipped.length;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  reveal(
                    0,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Eyebrow('CM Rewards', color: c.positiveInk),
                              const SizedBox(height: 6),
                              const Text('Treat yourself', style: AppText.display),
                            ],
                          ),
                        ),
                        Pressable(
                          onTap: () => showHowToEarnSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                CMIcon(CMGlyph.help, size: 17, color: c.primaryInk),
                                const SizedBox(width: 4),
                                Text(
                                  'How to earn',
                                  style: TextStyle(color: c.primaryInk, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  reveal(1, _BalanceStrip(points: state.points, unlocked: state.unlockedCount)),
                  const SizedBox(height: 18),
                  reveal(
                    2,
                    SegmentedTabs(
                      labels: ['Redeem', walletCount > 0 ? 'Wallet ($walletCount)' : 'Wallet', 'Tiers'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...switch (_tab) {
            0 => _redeemSlivers(state),
            1 => _walletSlivers(wallet, clipped),
            _ => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: TierLadder(lifetimePoints: state.lifetimePoints),
                ),
              ),
            ],
          },
          SliverToBoxAdapter(child: SizedBox(height: bottomInset(context))),
        ],
      ),
    );
  }

  List<Widget> _redeemSlivers(RewardsState state) {
    final visible = rewards.where((r) => _category == null || r.category == _category).toList();
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: ChipFilter<RewardCategory?>(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            options: [(null, 'All'), for (final cat in RewardCategory.values) (cat, cat.label)],
            selected: _category,
            onSelected: (value) => setState(() => _category = value),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        sliver: SliverGrid(
          // Two columns on phones, three or more on tablets.
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: context.textHeight(258, textShare: 0.45),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => FadeSlideIn(
              key: ValueKey('${_category?.name}-${visible[index].id}'),
              delay: Duration(milliseconds: 45 * index),
              child: RewardCard(reward: visible[index], balance: state.points, onRedeem: () => _redeem(visible[index])),
            ),
            childCount: visible.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _walletSlivers(List<ActiveReward> wallet, List<Deal> clipped) {
    if (wallet.isEmpty && clipped.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: CMGlyph.wallet,
            title: 'Your wallet is empty',
            body: 'Redeemed rewards and clipped offers show up here, ready to scan.',
            action: SecondaryButton(
              label: 'Browse rewards',
              icon: CMGlyph.giftFill,
              onPressed: () => setState(() => _tab = 0),
            ),
          ),
        ),
      ];
    }
    return [
      if (wallet.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: SectionHeader('My Wallet', subtitle: 'Active codes, ready at the register'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: wallet.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => FadeSlideIn(child: WalletTile(active: wallet[index])),
          ),
        ),
      ],
      if (clipped.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: SectionHeader('Clipped offers', subtitle: 'Applied automatically when you scan'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: context.textHeight(252, textShare: 0.4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: clipped.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => DealCard(deal: clipped[index], clipped: true),
            ),
          ),
        ),
      ],
    ];
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.points, required this.unlocked});

  final int points;
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return BurgundySurface(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available balance', style: TextStyle(color: Brand.white.withValues(alpha: 0.75), fontSize: 13)),
                  AnimatedCount(
                    value: points,
                    builder: (context, value) => Text(
                      '${formatNumber(value)} pts',
                      style: AppText.headline.copyWith(color: Brand.white, fontSize: 30, fontFeatures: AppText.tabular),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Brand.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(
                '$unlocked of ${rewards.length} unlocked',
                style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// The reward's photo, or its emoji on a brand-tinted disc.
class RewardArt extends StatelessWidget {
  const RewardArt({super.key, required this.reward, this.size = 80, this.locked = false});

  final Reward reward;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final photo = reward.photo;
    if (photo != null) {
      final image = ClipOval(
        child: SizedBox.square(dimension: size, child: BrandPhoto(photo)),
      );
      return locked ? ColorFiltered(colorFilter: _greyscale, child: image) : image;
    }
    final emoji = Text(reward.emoji, style: TextStyle(fontSize: size * 0.46));
    final fill = reward.category == RewardCategory.fuel || reward.category == RewardCategory.extras
        ? [c.positiveSoft, c.surfaceAlt]
        : [c.primarySoft, c.surfaceAlt];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: fill),
      ),
      child: locked ? ColorFiltered(colorFilter: _greyscale, child: emoji) : emoji,
    );
  }
}

class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.reward, required this.balance, required this.onRedeem});

  final Reward reward;
  final int balance;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final locked = balance < reward.points;
    final progress = (balance / reward.points).clamp(0.0, 1.0);

    return Pressable(
      onTap: locked ? null : onRedeem,
      child: Panel(
        padding: const EdgeInsets.all(14),
        radius: 24,
        child: Column(
          children: [
            Row(
              children: [
                CMIcon(reward.category.icon, size: 15, color: c.muted),
                const SizedBox(width: 4),
                Text(
                  reward.category.label,
                  style: TextStyle(fontSize: 11.5, color: c.muted, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (locked) CMIcon(CMGlyph.lock, size: 15, color: c.hint),
              ],
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: locked ? 0.6 : 1,
              child: RewardArt(reward: reward, size: 74, locked: locked),
            ),
            const SizedBox(height: 12),
            Text(
              reward.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatNumber(reward.points)} pts',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: locked ? c.muted : c.primaryInk,
                fontFeatures: AppText.tabular,
              ),
            ),
            const Spacer(),
            if (locked) ...[ProgressBar(value: progress, height: 5), const SizedBox(height: 10)],
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton(
                onPressed: locked
                    ? null
                    : () {
                        RewardsScope.read(context).haptic();
                        onRedeem();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Brand.white,
                  disabledBackgroundColor: c.faint,
                  disabledForegroundColor: c.muted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    locked ? '${formatNumber(reward.points - balance)} to go' : 'Redeem',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class WalletTile extends StatelessWidget {
  const WalletTile({super.key, required this.active});

  final ActiveReward active;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      onTap: () => showRewardTicket(context, active),
      scale: 0.98,
      child: Panel(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Row(
          children: [
            RewardArt(reward: active.reward, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active.reward.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  TickBuilder(
                    builder: (context) => Text(
                      'Expires in ${formatCountdown(active.expiresAt.difference(DateTime.now()))}',
                      style: TextStyle(
                        color: c.primaryInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconTile(icon: CMGlyph.qr, size: 40),
          ],
        ),
      ),
    );
  }
}

/// The three tiers side by side as a ladder, with the member's progress.
class TierLadder extends StatelessWidget {
  const TierLadder({super.key, required this.lifetimePoints});

  final int lifetimePoints;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final current = Tier.forPoints(lifetimePoints);
    final next = current.next;
    final progress = next == null
        ? 1.0
        : ((lifetimePoints - current.threshold) / (next.threshold - current.threshold)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You’re a ${current.label}', style: AppText.headline.copyWith(fontSize: 22)),
                        Text(
                          '${formatNumber(lifetimePoints)} lifetime points',
                          style: TextStyle(color: c.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TierChip(tier: current, onDark: false),
                ],
              ),
              const SizedBox(height: 16),
              ProgressBar(value: progress, color: next?.color ?? c.accent, height: 10),
              const SizedBox(height: 8),
              Text(
                next == null
                    ? 'Top tier. Thanks for being an Insider.'
                    : '${formatNumber(max(0, next.threshold - lifetimePoints))} more points to reach ${next.label}',
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Side by side on wide pages, so the perks compare at a glance.
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              for (final tier in Tier.values)
                _TierCard(tier: tier, current: tier == current, reached: tier.index <= current.index),
            ];
            if (constraints.maxWidth < Breakpoints.twoColumn) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: card)],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.current, required this.reached});

  final Tier tier;
  final bool current;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final color = tier == Tier.insider ? c.accentInk : (tier == Tier.regular ? c.primaryInk : c.positiveInk);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: current ? color : c.line, width: current ? 2 : 1),
        boxShadow: current ? c.elevation() : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: CMGlyph.medal, color: color, background: color.withValues(alpha: 0.12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.label, style: AppText.headline.copyWith(fontSize: 21, color: color)),
                    Text(
                      tier.threshold == 0 ? 'Where everyone starts' : '${formatNumber(tier.threshold)} lifetime points',
                      style: TextStyle(color: c.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (current)
                const StatusPill(label: 'You', positive: true, dot: false)
              else if (!reached)
                CMIcon(CMGlyph.lock, color: c.hint, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          for (final (icon, perk) in tier.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CMIcon(icon, size: 18, color: reached ? color : c.hint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      perk,
                      style: TextStyle(color: reached ? c.ink : c.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showRewardTicket(BuildContext context, ActiveReward active, {bool celebrate = false}) {
  final animate = !MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: !celebrate,
    barrierLabel: 'Reward code',
    barrierColor: Brand.ink.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) => Stack(
      children: [
        if (celebrate && animate) const Positioned.fill(child: ConfettiBurst()),
        Center(
          child: RewardTicket(active: active, celebrate: celebrate),
        ),
      ],
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1).animate(curved), child: child),
      );
    },
  );
}

class RewardTicket extends StatelessWidget {
  const RewardTicket({super.key, required this.active, this.celebrate = false});

  final ActiveReward active;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final reward = active.reward;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: c.background,
            borderRadius: BorderRadius.circular(Radii.xl),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (celebrate) ...[
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(color: c.positive, shape: BoxShape.circle),
                        child: const CMIcon(CMGlyph.check, color: Brand.white, size: 42),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Reward Redeemed!', style: AppText.display),
                  ] else
                    Text(reward.name, style: AppText.headline),
                  const SizedBox(height: 4),
                  Text('Show this to cashier', style: TextStyle(fontSize: 15, color: c.muted)),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Brand.white,
                      borderRadius: BorderRadius.circular(Radii.lg),
                      boxShadow: c.elevation(),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                          child: Row(
                            children: [
                              Theme(
                                data: buildTheme(CMColors.light),
                                child: RewardArt(reward: reward, size: 54),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Brand.ink,
                                      ),
                                    ),
                                    Text(
                                      reward.description,
                                      style: TextStyle(color: Brand.ink.withValues(alpha: 0.55), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TicketDivider(notchColor: c.background),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 76,
                                width: double.infinity,
                                child: CustomPaint(painter: BarcodePainter(active.code)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                active.code,
                                style: const TextStyle(
                                  color: Brand.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  fontFeatures: AppText.tabular,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TickBuilder(
                    builder: (context) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CMIcon(CMGlyph.timer, size: 16, color: c.primaryInk),
                        const SizedBox(width: 6),
                        Text(
                          'Expires in ${formatCountdown(active.expiresAt.difference(DateTime.now()))}',
                          style: TextStyle(
                            color: c.primaryInk,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppText.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
