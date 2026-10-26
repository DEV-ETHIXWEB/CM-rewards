// Bugs found in QA, kept as tests so they stay fixed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_markets_rewards/main.dart';
import 'package:center_markets_rewards/widgets/cm_icons.dart';

Future<RewardsState> demo(WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final state = RewardsState();
  await tester.pumpWidget(CenterMarketsApp(state: state));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Explore in Demo Mode'));
  await tester.tap(find.text('Explore in Demo Mode'));
  await tester.pumpAndSettle();
  return state;
}

Future<void> openAccount(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^Account')).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('closing the Personal info sheet does not crash', (tester) async {
    final state = await demo(tester);
    await openAccount(tester);
    await tester.scrollUntilVisible(find.text('Personal info'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal info'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'not-an-email');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('That email doesn’t look right'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'akash@example.com');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.email, 'akash@example.com');
  });

  testWidgets('double-tapping redeem only redeems once and keeps the app on screen', (tester) async {
    final state = await demo(tester);
    await tester.tap(find.byKey(const ValueKey('nav-rewards')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Redeem').first);
    await tester.pumpAndSettle();
    final confirm = find.textContaining('Redeem for');
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.redeemedCount, 4);
    expect(state.wallet, hasLength(1));
    expect(find.text('Reward Redeemed!'), findsOneWidget);
  });

  testWidgets('Android back on another tab returns Home instead of closing', (tester) async {
    await demo(tester);
    await tester.tap(find.byKey(const ValueKey('nav-stores')));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Scan to earn'), findsOneWidget);
  });

  testWidgets('wrong codes lock sign-in after five tries', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(CenterMarketsApp(state: RewardsState()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();
    expect(find.text('Enter a valid US mobile number'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '5035550123');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Enter your code'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.enterText(find.byType(TextField), '000000');
      // Let the simulated verification finish.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }
    expect(find.text('Too many tries. Please wait a minute and try again.'), findsOneWidget);
  });

  testWidgets('custom icons keep their size inside larger fixed boxes', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 66, height: 66, child: CMIcon(CMGlyph.scan, size: 28))),
      ),
    );
    final paint = tester.getSize(find.descendant(of: find.byType(CMIcon), matching: find.byType(CustomPaint)));
    expect(paint, const Size(28, 28));
  });

  test('gifts to your own number or invalid numbers are refused', () {
    final state = RewardsState();
    expect(state.giftPoints(state.phoneDigits, 250), isFalse);
    expect(state.giftPoints('1234567890', 250), isFalse);
    expect(state.giftPoints('5035550100', 10), isFalse, reason: 'below the minimum');
    expect(state.points, 2340);
  });
}
