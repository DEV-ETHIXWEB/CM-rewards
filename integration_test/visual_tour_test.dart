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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Walks every screen and sheet of the real app on a device and pauses on each
// so a screenshot can be taken from outside (xcrun simctl io <device> screenshot).
//
//   flutter test integration_test/visual_tour_test.dart -d <id> --dart-define=TOUR_THEME=dark
const _theme = String.fromEnvironment('TOUR_THEME', defaultValue: 'light');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('visual tour', (tester) async {
    final prefix = _theme == 'dark' ? 'd_' : 'l_';

    Future<void> settle([int ms = 900]) async {
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> hold(String name) async {
      await settle(1000);
      // ignore: avoid_print
      print('SHOT $prefix$name');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2500)));
      await tester.pump();
    }

    Future<void> scroll(double dy, {bool last = false}) async {
      final finder = last ? find.byType(Scrollable).last : find.byType(Scrollable).first;
      await tester.drag(finder, Offset(0, -dy));
      await settle(700);
    }

    NavigatorState nav() => tester.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> pop() async {
      nav().pop();
      await settle(800);
    }

    BuildContext shell() => tester.element(find.byType(MainShell));

    Future<void> sheet(String name, Future<void> Function(BuildContext) open, {double scrollBy = 0}) async {
      open(shell()).ignore();
      await hold(name);
      if (scrollBy > 0) {
        await scroll(scrollBy, last: true);
        await hold('${name}_2');
      }
      await pop();
    }

    Future<void> screen(String name, Widget page, {List<double> scrolls = const []}) async {
      Navigator.of(shell()).push(MaterialPageRoute<void>(builder: (_) => page)).ignore();
      await hold(name);
      for (var i = 0; i < scrolls.length; i++) {
        await scroll(scrolls[i], last: true);
        await hold('${name}_${i + 2}');
      }
      await pop();
    }

    final state = RewardsState()..themeMode = _theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    await tester.pumpWidget(CenterMarketsApp(state: state));
    await settle(1100);
    await hold('splash');
    await settle(2500);
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await hold('login');

    // Sign-in flow.
    final login = tester.element(find.byType(LoginScreen));
    Navigator.of(login)
        .push(MaterialPageRoute<void>(builder: (_) => const OtpScreen(phoneDigits: '5035550123')))
        .ignore();
    await hold('otp');
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump(const Duration(seconds: 1));
    await hold('otp_error');
    await pop();
    Navigator.of(login).push(MaterialPageRoute<void>(builder: (_) => const PersonalizeScreen())).ignore();
    await hold('personalize');
    await scroll(500, last: true);
    await hold('personalize_2');
    await pop();

    await tester.ensureVisible(find.text('Explore in Demo Mode'));
    await tester.tap(find.text('Explore in Demo Mode'));
    await settle(2000);

    // Home, top to bottom.
    await hold('home_1');
    for (var i = 2; i <= 6; i++) {
      await scroll(560);
      await hold('home_$i');
    }

    await sheet('deal', (c) => showDealSheet(c, deals.first));
    await sheet('fuel', showFuelSheet, scrollBy: 400);
    await sheet('gift', showGiftSheet);
    await sheet('referral', showReferralSheet);
    await sheet('about', showAboutSheet, scrollBy: 500);
    await sheet('how_to_earn', showHowToEarnSheet);
    await screen('notifications', const NotificationsScreen());
    await screen('activity', const ActivityScreen(), scrolls: [600]);

    // Member pass and a simulated scan.
    showMemberPass(shell());
    await hold('pass');
    await scroll(300, last: true);
    await hold('pass_2');
    await tester.tap(find.text('Demo: simulate a scan at checkout'));
    await settle(2500);
    await hold('pass_success');
    await pop();

    // Order ahead.
    await tester.tap(find.byKey(const ValueKey('nav-order')));
    await hold('order_1');
    await scroll(600);
    await hold('order_2');
    await sheet('item', (c) => showMenuItemSheet(c, menu.firstWhere((m) => m.id == 'latte')));
    state.addToCart(menu.first, 0, 1);
    state.addToCart(menu.firstWhere((m) => m.id == 'latte'), 2, 2);
    await hold('order_cart');
    await sheet('checkout', showCheckoutSheet, scrollBy: 600);
    final order = state.placeOrder(storeNumber: 1, pickupMinutes: 10, payment: 'Apple Pay');
    await screen('tracker', OrderTrackerScreen(order: order), scrolls: [500]);

    // Rewards.
    await tester.tap(find.byKey(const ValueKey('nav-rewards')));
    await hold('rewards_1');
    await scroll(600);
    await hold('rewards_2');
    final active = state.redeem(rewards.first)!;
    showRewardTicket(shell(), active, celebrate: true).ignore();
    await hold('ticket');
    await pop();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await settle();
    await tester.tap(find.textContaining('Wallet'));
    await hold('wallet');
    await tester.tap(find.text('Tiers'));
    await hold('tiers_1');
    await scroll(600);
    await hold('tiers_2');

    // Stores.
    await tester.tap(find.byKey(const ValueKey('nav-stores')));
    await hold('stores');
    await tester.tap(find.text('Map'));
    await hold('map');
    await tester.tap(find.text('List'));
    await settle();
    await sheet('store', (c) => showStoreSheet(c, stores[1]), scrollBy: 600);

    // Account.
    await screen('account', const AccountScreen(), scrolls: [600, 600, 600]);
    await sheet('avatar', showAvatarPicker);
    await sheet('edit_profile', showEditProfileSheet);
    await sheet('help', showHelpSheet);
  });
}
