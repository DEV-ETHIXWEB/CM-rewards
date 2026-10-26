import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/cm_icons.dart';

enum ActivityFilter { all, earned, redeemed }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = RewardsScope.of(context);
    final now = DateTime.now();
    final thisMonth = state.transactions.where((t) => t.date.year == now.year && t.date.month == now.month);
    final earned = thisMonth.where((t) => t.isEarn).fold<int>(0, (sum, t) => sum + t.points);
    final redeemed = thisMonth.where((t) => !t.isEarn).fold<int>(0, (sum, t) => sum - t.points);
    final items = state.transactions.where((t) {
      return switch (_filter) {
        ActivityFilter.all => true,
        ActivityFilter.earned => t.isEarn,
        ActivityFilter.redeemed => !t.isEarn,
      };
    }).toList();

    // Points earned in each of the last six weeks, oldest first.
    final weekStart = startOfWeek(now);
    final weekly = [
      for (var w = 5; w >= 0; w--)
        state.transactions
            .where((t) {
              final start = weekStart.subtract(Duration(days: 7 * w));
              return t.isEarn && !t.date.isBefore(start) && t.date.isBefore(start.add(const Duration(days: 7)));
            })
            .fold<int>(0, (sum, t) => sum + t.points),
    ];

    final rows = <Widget>[];
    String? lastDay;
    for (var i = 0; i < items.length; i++) {
      final day = relativeDay(items[i].date);
      if (day != lastDay) {
        rows.add(Padding(padding: EdgeInsets.fromLTRB(6, rows.isEmpty ? 0 : 18, 6, 8), child: Eyebrow(day)));
        lastDay = day;
      }
      rows.add(
        FadeSlideIn(
          key: ValueKey('${_filter.name}-$i-${items[i].date.millisecondsSinceEpoch}'),
          delay: Duration(milliseconds: min(30 * i, 400)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              radius: 22,
              child: TransactionTile(transaction: items[i]),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: ContentAppBar(AppBar(title: const Text('Activity'))),
      body: ContentWidth(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            reveal(
              0,
              BurgundySurface(
                radius: 26,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('${months[now.month - 1]} ${now.year}', color: Brand.white.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _summary('Earned', '+${formatNumber(earned)}', CMGlyph.trendUp)),
                          Container(width: 1, height: 40, color: Brand.white.withValues(alpha: 0.2)),
                          const SizedBox(width: 16),
                          Expanded(child: _summary('Redeemed', formatNumber(redeemed), CMGlyph.giftFill)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _WeeklyBars(values: weekly),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const CMIcon(CMGlyph.savings, size: 18, color: Brand.greenBright),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You’ve saved ${formatMoney(state.savedCents)} with CM Rewards',
                              style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            reveal(
              1,
              SegmentedTabs(
                labels: const ['All', 'Earned', 'Redeemed'],
                index: _filter.index,
                onChanged: (i) => setState(() => _filter = ActivityFilter.values[i]),
              ),
            ),
            const SizedBox(height: 18),
            if (rows.isEmpty)
              const EmptyState(
                icon: CMGlyph.receipt,
                title: 'No activity yet',
                body: 'Your points history will show up here.',
              )
            else
              ...rows,
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, String value, CMGlyph icon) {
    return Row(
      children: [
        CMIcon(icon, color: Brand.greenBright),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppText.headline.copyWith(color: Brand.white, fontSize: 24, fontFeatures: AppText.tabular),
              ),
              Text(label, style: TextStyle(color: Brand.white.withValues(alpha: 0.75), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final peak = max(1, values.reduce(max));
    return Semantics(
      label: 'Points earned per week for the last six weeks: ${values.join(', ')}',
      child: SizedBox(
        height: context.textHeight(86, textShare: 0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bars share whatever height the label leaves, so large text never overflows.
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) => Align(
                            alignment: Alignment.bottomCenter,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: values[i] / peak),
                              duration: Duration(milliseconds: 600 + 80 * i),
                              curve: Motion.standard,
                              builder: (context, v, _) => Container(
                                height: max(4, constraints.maxHeight * v),
                                decoration: BoxDecoration(
                                  color: i == values.length - 1
                                      ? Brand.greenBright
                                      : Brand.white.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i == values.length - 1 ? 'Now' : '${values.length - 1 - i}w',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(color: Brand.white.withValues(alpha: 0.6), fontSize: 11),
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

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final PointsTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final earned = transaction.isEarn;
    final color = earned ? c.positiveInk : c.primaryInk;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconTile(
            icon: transaction.icon,
            size: 44,
            color: color,
            background: earned ? c.positiveSoft : c.primarySoft,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.detail}  ·  ${relativeDay(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${earned ? '+' : ''}${formatNumber(transaction.points)}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color, fontFeatures: AppText.tabular),
          ),
        ],
      ),
    );
  }
}
