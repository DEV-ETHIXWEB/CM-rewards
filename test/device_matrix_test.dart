// Renders every major screen across phone, foldable and tablet sizes, with
// large accessibility text and both appearances. Any overflow or layout
// exception fails the test, so regressions show up before they ship.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_markets_rewards/data/catalog.dart';
import 'package:center_markets_rewards/main.dart';
import 'package:center_markets_rewards/screens/activity.dart';
import 'package:center_markets_rewards/widgets/common.dart';

import 'support/fonts.dart';

class Device {
  const Device(this.name, this.width, this.height);

  final String name;
  final double width;
  final double height;
}

const devices = [
  Device('iPhone SE (1st gen)', 320, 568),
  Device('iPhone SE (3rd gen)', 375, 667),
  Device('Small Android', 360, 640),
  Device('Galaxy Z Fold, folded', 344, 882),
  Device('iPhone 17', 393, 852),
  Device('iPhone 17 Pro Max', 440, 956),
  Device('Galaxy Z Fold, open', 712, 832),
  Device('iPad mini', 744, 1133),
  Device('iPad Air', 820, 1180),
  Device('iPad Pro 13, landscape', 1376, 1032),
];

const textScales = [1.0, 2.0];

Future<void> tour(WidgetTester tester, RewardsState state) async {
  Future<void> settle() => tester.pumpAndSettle(const Duration(milliseconds: 100));

  Future<void> closeTop() async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await settle();
  }

  await tester.pump(const Duration(seconds: 3));
  await settle();

  await tester.ensureVisible(find.text('Explore in Demo Mode'));
  await settle();
  await tester.tap(find.text('Explore in Demo Mode'));
  await settle();

  // Scroll the whole home feed so every section lays out.
  final home = find.byType(Scrollable).first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(home, const Offset(0, -500));
    await settle();
  }

  for (final tab in ['order', 'rewards', 'stores']) {
    await tester.tap(find.byKey(ValueKey('nav-$tab')));
    await settle();
  }
  await tester.tap(find.text('Map'));
  await settle();
  await tester.tap(find.text('List'));
  await settle();

  await tester.tap(find.byKey(const ValueKey('nav-rewards')));
  await settle();
  // With large text on small phones the tabs start below the fold.
  await tester.ensureVisible(find.text('Tiers'));
  await settle();
  await tester.tap(find.text('Tiers'));
  await settle();

  await tester.tap(find.byKey(const ValueKey('nav-scan')));
  await settle();
  await closeTop();

  // The bag, the order tracker and pushed screens.
  await tester.tap(find.byKey(const ValueKey('nav-order')));
  await settle();
  state.addToCart(menu.first, 0, 2);
  await settle();

  await tester.tap(find.text('View bag'));
  await settle();
  await closeTop();

  state.placeOrder(storeNumber: 1, pickupMinutes: 10, payment: 'Apple Pay');
  await settle();
  await tester.tap(find.byKey(const ValueKey('nav-home')));
  await settle();
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 6000));
  await settle();
  expect(find.textContaining('Order #'), findsOneWidget);

  await tester.tap(find.bySemanticsLabel(RegExp('^Account')).first);
  await settle();
  final account = find.byType(Scrollable).last;
  for (var i = 0; i < 4; i++) {
    await tester.drag(account, const Offset(0, -500));
    await settle();
  }
  await closeTop();

  // The bell button itself; the label also lands on its whole header row.
  await tester.tap(find.byWidgetPredicate((w) => w is CircleIconButton && w.label == 'Notifications'));
  await settle();
  await closeTop();

  // Activity has a chart and a summary that must fit at every size.
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.push(MaterialPageRoute<void>(builder: (_) => const ActivityScreen())).ignore();
  await settle();
  await tester.drag(find.byType(Scrollable).last, const Offset(0, -800));
  await settle();
  await closeTop();
}

void main() {
  setUpAll(loadAppFonts);

  for (final device in devices) {
    for (final scale in textScales) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        // Big text matters most on phones; keep the matrix quick elsewhere.
        if (scale > 1 && device.width >= 600 && mode == ThemeMode.dark) continue;
        testWidgets('${device.name} · text ${scale}x · ${mode.name}', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
            disableAnimations: true,
          );
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.view.physicalSize = Size(device.width * 3, device.height * 3);
          tester.view.devicePixelRatio = 3;
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          addTearDown(() {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
            tester.view.reset();
          });

          final state = RewardsState()..themeMode = mode;
          await tester.pumpWidget(CenterMarketsApp(state: state));
          await tour(tester, state);
        });
      }
    }
  }
}
