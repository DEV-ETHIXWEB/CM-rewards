// Renders every screen and sheet to PNGs for design review, without a device:
//   flutter test test/tools/screens_test.dart --dart-define=OUT=/path/dir \
//     [--dart-define=DEVICE=ipad_air] [--dart-define=THEME=dark]
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_markets_rewards/data/catalog.dart';
import 'package:center_markets_rewards/main.dart';
import 'package:center_markets_rewards/screens/account.dart';
import 'package:center_markets_rewards/screens/activity.dart';
import 'package:center_markets_rewards/screens/auth.dart';
import 'package:center_markets_rewards/screens/home.dart';
import 'package:center_markets_rewards/screens/notifications.dart';
import 'package:center_markets_rewards/screens/order.dart';
import 'package:center_markets_rewards/screens/pass.dart';
import 'package:center_markets_rewards/screens/rewards.dart';
import 'package:center_markets_rewards/screens/sheets.dart';
import 'package:center_markets_rewards/screens/shell.dart';
import 'package:center_markets_rewards/screens/stores.dart';
import 'package:center_markets_rewards/widgets/avatar.dart';

import '../support/fonts.dart';

const _out = String.fromEnvironment('OUT');
const _device = String.fromEnvironment('DEVICE', defaultValue: 'ipad_air');
const _theme = String.fromEnvironment('THEME', defaultValue: 'light');
const _scale = String.fromEnvironment('SCALE', defaultValue: '1');

const _devices = {
  'se1': Size(320, 568),
  'iphone': Size(393, 852),
  'fold_open': Size(712, 832),
  'ipad_mini': Size(744, 1133),
  'ipad_air': Size(820, 1180),
  'ipad_air_land': Size(1180, 820),
  'ipad_pro_land': Size(1376, 1032),
};

void main() {
  setUpAll(loadAppFonts);

  testWidgets('screens', (tester) async {
    if (_out.isEmpty) return;
    Directory(_out).createSync(recursive: true);
    final size = _devices[_device]!;
    final tablet = size.shortestSide >= 600;
    tester.platformDispatcher.textScaleFactorTestValue = double.parse(_scale);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    tester.view.padding = FakeViewPadding(top: (tablet ? 24 : 47) * 2.0, bottom: (tablet ? 20 : 34) * 2.0);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString().split('\n').first);
    addTearDown(() => FlutterError.onError = previous);

    final key = GlobalKey();
    final state = RewardsState()..themeMode = _theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CenterMarketsApp(state: state),
      ),
    );

    Future<void> settle([int ms = 600]) async {
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Let asset images decode.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump();
    }

    var n = 0;
    Future<void> shot(String name) async {
      await settle();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final file = '$_out/${(n++).toString().padLeft(2, '0')}_$name.png';
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(file).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      if (errors.isNotEmpty) {
        // ignore: avoid_print
        print('ERRORS at $name: ${errors.toSet().join(' | ')}');
        errors.clear();
      }
    }

    Future<void> scroll(double dy, {bool last = false}) async {
      final finder = last ? find.byType(Scrollable).last : find.byType(Scrollable).first;
      await tester.drag(finder, Offset(0, -dy), warnIfMissed: false);
      await settle(400);
    }

    NavigatorState nav() => tester.state<NavigatorState>(find.byType(Navigator).first);
    Future<void> pop() async {
      nav().pop();
      await settle(800);
    }

    BuildContext shell() => tester.element(find.byType(MainShell));
    final page = size.height * 0.7;

    Future<void> sheet(String name, Future<void> Function(BuildContext) open, {int scrolls = 0}) async {
      open(shell()).ignore();
      await shot(name);
      for (var i = 0; i < scrolls; i++) {
        await scroll(page * 0.8, last: true);
        await shot('${name}_${i + 2}');
      }
      await pop();
    }

    Future<void> screen(String name, Widget widget, {int scrolls = 0}) async {
      Navigator.of(shell()).push(MaterialPageRoute<void>(builder: (_) => widget)).ignore();
      await shot(name);
      for (var i = 0; i < scrolls; i++) {
        await scroll(page, last: true);
        await shot('${name}_${i + 2}');
      }
      await pop();
    }

    await tester.pump(const Duration(milliseconds: 900));
    await shot('splash');
    await tester.pump(const Duration(seconds: 3));
    await settle(1500);
    await shot('login');
    final login = tester.element(find.byType(LoginScreen));
    Navigator.of(login)
        .push(MaterialPageRoute<void>(builder: (_) => const OtpScreen(phoneDigits: '5035550123')))
        .ignore();
    await shot('otp');
    await tester.enterText(find.byType(TextField), '000000');
    await shot('otp_error');
    Navigator.of(login).pop();
    await settle(800);
    Navigator.of(login).push(MaterialPageRoute<void>(builder: (_) => const PersonalizeScreen())).ignore();
    await shot('personalize');
    await scroll(page, last: true);
    await shot('personalize_2');
    Navigator.of(login).pop();
    await settle(800);

    await tester.ensureVisible(find.text('Explore in Demo Mode'));
    await tester.tap(find.text('Explore in Demo Mode'));
    await settle(2000);

    await shot('home_1');
    for (var i = 2; i <= 6; i++) {
      await scroll(page);
      await shot('home_$i');
    }
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 9000));
    await settle();

    await sheet('deal', (c) => showDealSheet(c, deals.first));
    await sheet('fuel', showFuelSheet, scrolls: 1);
    await sheet('gift', showGiftSheet);
    await sheet('referral', showReferralSheet);
    await sheet('about', showAboutSheet, scrolls: 1);
    await sheet('how_to_earn', showHowToEarnSheet);
    await screen('notifications', const NotificationsScreen());
    await screen('activity', const ActivityScreen(), scrolls: 1);

    showMemberPass(shell());
    await shot('pass');
    await scroll(300, last: true);
    await shot('pass_2');
    await pop();

    await tester.tap(find.byKey(const ValueKey('nav-order')));
    await shot('order_1');
    await scroll(page);
    await shot('order_2');
    await scroll(page);
    await shot('order_3');
    await sheet('item', (c) => showMenuItemSheet(c, menu.firstWhere((m) => m.id == 'latte')));
    state.addToCart(menu.first, 0, 1);
    state.addToCart(menu.firstWhere((m) => m.id == 'latte'), 2, 2);
    await shot('order_cart');
    await sheet('checkout', showCheckoutSheet, scrolls: 1);
    final order = state.placeOrder(storeNumber: 1, pickupMinutes: 10, payment: 'Apple Pay');
    await screen('tracker', OrderTrackerScreen(order: order), scrolls: 1);

    await tester.tap(find.byKey(const ValueKey('nav-rewards')));
    await shot('rewards_1');
    await scroll(page);
    await shot('rewards_2');
    await scroll(page);
    await shot('rewards_3');
    final active = state.redeem(rewards.first)!;
    showRewardTicket(shell(), active).ignore();
    await shot('ticket');
    await pop();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 9000));
    await settle();
    // The tab itself, not the toast that mentions the wallet.
    ScaffoldMessenger.of(shell()).hideCurrentSnackBar();
    await settle();
    await tester.tap(find.text('Wallet (1)'));
    await shot('wallet');
    await tester.tap(find.text('Tiers'));
    await shot('tiers_1');
    await scroll(page);
    await shot('tiers_2');

    await tester.tap(find.byKey(const ValueKey('nav-stores')));
    await shot('stores');
    await scroll(page);
    await shot('stores_2');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 9000));
    await settle();
    await tester.tap(find.text('Map'));
    await shot('map');
    await tester.tap(find.text('List'));
    await settle();
    await sheet('store', (c) => showStoreSheet(c, stores[1]), scrolls: 1);

    await screen('account', const AccountScreen(), scrolls: 3);
    await sheet('avatar', showAvatarPicker);
    await sheet('edit_profile', showEditProfileSheet);
    await sheet('help', showHelpSheet);
    await sheet('home_store', showHomeStorePicker);
    await sheet('payments', showPaymentsSheet);
    await sheet('interests', showInterestsSheet);
    await sheet('notif_prefs', showNotificationPrefsSheet);
  });
}
