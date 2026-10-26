import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_markets_rewards/data/catalog.dart';
import 'package:center_markets_rewards/main.dart';
import 'package:center_markets_rewards/screens/account.dart';
import 'package:center_markets_rewards/screens/stores.dart';

Future<RewardsState> launchToLogin(WidgetTester tester) async {
  // Reduced motion keeps looping animations from blocking pumpAndSettle.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final state = RewardsState();
  await tester.pumpWidget(CenterMarketsApp(state: state));
  expect(find.text('Always close. Always convenient.'), findsOneWidget);
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  return state;
}

Future<void> enterDemo(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Explore in Demo Mode'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Explore in Demo Mode'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('splash leads to login, demo mode reaches home', (tester) async {
    await launchToLogin(tester);
    expect(find.text('Sign in or join CM Rewards'), findsOneWidget);

    await enterDemo(tester);
    expect(find.text('Scan to earn'), findsOneWidget);
    expect(find.textContaining('2,340', findRichText: true), findsWidgets);
    expect(find.text('Akash'), findsOneWidget);
  });

  testWidgets('member pass scan earns points', (tester) async {
    final state = await launchToLogin(tester);
    await enterDemo(tester);

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpAndSettle();
    expect(find.text('Member pass'), findsOneWidget);

    await tester.ensureVisible(find.text('Demo: simulate a scan at checkout'));
    await tester.tap(find.text('Demo: simulate a scan at checkout'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('points earned'), findsOneWidget);
    expect(state.points, greaterThan(2340));
  });

  testWidgets('redeeming a reward deducts points and fills the wallet', (tester) async {
    final state = await launchToLogin(tester);
    await enterDemo(tester);

    await tester.tap(find.byKey(const ValueKey('nav-rewards')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Redeem').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redeem for 500 pts'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Reward Redeemed!'), findsOneWidget);
    expect(find.text('Show this to cashier'), findsOneWidget);
    expect(state.points, 1840);
    expect(state.wallet, hasLength(1));

    await tester.ensureVisible(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Reward Redeemed!'), findsNothing);
    expect(find.text('1,840 pts'), findsOneWidget);

    await tester.tap(find.text('Wallet (1)'));
    await tester.pumpAndSettle();
    expect(find.text('My Wallet'), findsOneWidget);
  });

  testWidgets('order ahead: add to bag, check out, track', (tester) async {
    final state = await launchToLogin(tester);
    await enterDemo(tester);

    await tester.tap(find.byKey(const ValueKey('nav-order')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pepperoni Slice'),
      300,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    await tester.tap(find.text('Pepperoni Slice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to bag'));
    await tester.pumpAndSettle();
    expect(state.cartCount, 1);

    await tester.tap(find.text('View bag'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Place order'), 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(state.activeOrder, isNotNull);
    expect(state.cartCount, 0);
    expect(state.points, greaterThan(2340));
    expect(find.text('Order #${state.activeOrder!.number}'), findsOneWidget);
  });

  testWidgets('stores can be searched and favorited', (tester) async {
    final state = await launchToLogin(tester);
    await enterDemo(tester);

    await tester.tap(find.byKey(const ValueKey('nav-stores')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'keizer');
    await tester.pumpAndSettle();
    expect(find.text('Center Market #3'), findsOneWidget);
    expect(find.text('Center Market #1'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Add to favorites').first);
    await tester.pumpAndSettle();
    expect(state.favoriteStores, contains(3));
  });

  testWidgets('account: appearance, haptics and FAQ', (tester) async {
    final state = await launchToLogin(tester);
    await enterDemo(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('^Account')));
    await tester.pumpAndSettle();
    final dark = find.bySemanticsLabel(RegExp('^Dark appearance'));
    await tester.scrollUntilVisible(dark, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(dark);
    await tester.pumpAndSettle();
    await tester.tap(dark);
    await tester.pumpAndSettle();
    expect(state.themeMode, ThemeMode.dark);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('haptics-switch')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('haptics-switch')));
    await tester.pumpAndSettle();
    expect(state.hapticsEnabled, isFalse);

    await tester.scrollUntilVisible(find.text('Help & FAQ'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Help & FAQ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How do I earn points?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('10 points for every'), findsOneWidget);
  });

  test('rewards start at 500 points and referrals pay 50', () {
    expect(rewards.map((r) => r.points).reduce((a, b) => a < b ? a : b), 500);
    expect(rewards.firstWhere((r) => r.id == 'cooldrink').points, 500);
    expect(RewardsState.referralBonus, 50);
  });

  test('gifting points checks the balance', () {
    final state = RewardsState();
    expect(state.giftPoints('5035550100', 9000), isFalse);
    expect(state.giftPoints('5035550100', 250), isTrue);
    expect(state.points, 2090);
    expect(state.transactions.first.title, 'Gifted points');
  });

  test('tiers follow lifetime points', () {
    final state = RewardsState();
    expect(state.tier.label, 'Regular');
    state.lifetimePoints = 6100;
    expect(state.tier.label, 'Insider');
    // \$10 at 10 points per dollar, 1.5x for Insiders.
    expect(state.pointsFor(1000), 150);
  });

  testWidgets('the demo is labelled and shows no fictional phone numbers', (tester) async {
    final state = await launchToLogin(tester);
    expect(find.text('Mobile number'), findsOneWidget);
    await enterDemo(tester);

    expect(find.text('DEMO'), findsOneWidget);
    expect(state.memberId, 'CM 4821 093 517');
    expect(stores.every((s) => s.phone == null), isTrue);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const AccountScreen()))
        .ignore();
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo account'), findsOneWidget);
    expect(find.textContaining('555'), findsNothing);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo build, sample data'), findsOneWidget);
  });

  testWidgets('stores: no Call buttons without a number, locate opens the map', (tester) async {
    await launchToLogin(tester);
    await enterDemo(tester);
    await tester.tap(find.byKey(const ValueKey('nav-stores')));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Call'), findsNothing);
    await tester.tap(find.byTooltip('Stores near me'));
    await tester.pumpAndSettle();
    expect(find.byType(AreaMap), findsOneWidget);
    // The nearest store is picked on the map.
    expect(find.text(stores.reduce((a, b) => a.distance <= b.distance ? a : b).name), findsWidgets);

    showStoreSheet(tester.element(find.byType(AreaMap)), stores[1]).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Call'), findsNothing);
    expect(find.text('Get Directions'), findsOneWidget);
  });
}
