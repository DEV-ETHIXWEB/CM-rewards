import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/cm_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NoticeKind? _kind;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final items = state.notifications.where((n) => _kind == null || n.kind == _kind).toList();
    final today = items.where((n) => n.age.inHours < 24).toList();
    final earlier = items.where((n) => n.age.inHours >= 24).toList();

    Widget tile(AppNotification n, int index) {
      final unread = !state.readNotifications.contains(n.id);
      return reveal(
        index,
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              state
                ..haptic()
                ..dismissNotification(n.id);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.md)),
              child: CMIcon(CMGlyph.trash, color: c.primaryInk),
            ),
            child: Pressable(
              onTap: () => state.markRead(n.id),
              scale: 0.98,
              child: AnimatedContainer(
                duration: Motion.medium,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: unread ? c.surface : c.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: unread ? c.line : Colors.transparent),
                  boxShadow: unread ? c.elevation() : const [],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(
                      icon: n.kind.icon,
                      color: n.kind == NoticeKind.deals || n.kind == NoticeKind.orders ? c.positiveInk : c.primaryInk,
                      background: n.kind == NoticeKind.deals || n.kind == NoticeKind.orders
                          ? c.positiveSoft
                          : c.primarySoft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(timeAgo(n.age), style: TextStyle(fontSize: 12, color: c.muted)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(n.body, style: TextStyle(color: c.muted, fontSize: 13.5, height: 1.4)),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: unread ? 1 : 0,
                      duration: Motion.medium,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
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

    return Scaffold(
      appBar: ContentAppBar(
        AppBar(
          title: const Text('Notifications'),
          actions: [
            if (state.unreadCount > 0)
              TextButton(
                onPressed: state.markAllRead,
                style: TextButton.styleFrom(foregroundColor: c.primaryInk),
                child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
          children: [
            ChipFilter<NoticeKind?>(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              options: [(null, 'All'), for (final k in NoticeKind.values) (k, k.label)],
              selected: _kind,
              onSelected: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: items.isEmpty
                  ? const EmptyState(
                      icon: CMGlyph.bellOff,
                      title: 'You’re all caught up',
                      body: 'We’ll let you know about new deals, rewards and your orders.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (today.isNotEmpty) ...[
                          const Padding(padding: EdgeInsets.fromLTRB(6, 0, 6, 10), child: Eyebrow('Today')),
                          for (final (i, n) in today.indexed) tile(n, i),
                        ],
                        if (earlier.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(6, today.isEmpty ? 0 : 12, 6, 10),
                            child: const Eyebrow('Earlier'),
                          ),
                          for (final (i, n) in earlier.indexed) tile(n, today.length + i),
                        ],
                        const SizedBox(height: 8),
                        Center(
                          child: Text('Swipe left to dismiss', style: TextStyle(fontSize: 12, color: c.hint)),
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
