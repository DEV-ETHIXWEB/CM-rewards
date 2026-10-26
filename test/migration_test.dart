import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:center_markets_rewards/data/catalog.dart';
import 'package:center_markets_rewards/main.dart';
import 'package:center_markets_rewards/state/storage.dart';

// Exactly what version 1.x wrote to plain preferences (5 points per dollar).
final v1Data = {
  'signedIn': true,
  'name': 'Jordan Lee',
  'phone': '5035550199',
  'points': 3210,
  'lifetime': 5400,
  'visits': 61,
  'redeemed': 9,
  'notifications': false,
  'haptics': false,
  'howItWorksDismissed': true,
  'transactions': [
    {
      'type': 'purchase',
      'title': 'In-store purchase',
      'detail': '#2 Oak Ave · \$9.10',
      'points': 45,
      'date': '2026-09-01T12:00:00.000',
    },
    {
      'type': 'redeem',
      'title': 'Redeemed Free Coffee',
      'detail': '#1 Main St',
      'points': -200,
      'date': '2026-08-28T08:00:00.000',
    },
  ],
  'favorites': [2, 4],
  'clipped': ['Icee Any Size'],
  'read': ['n1'],
  'dismissed': ['n5'],
};

Map<String, dynamic> saved(MemoryStore store) =>
    jsonDecode(store.values[RewardsState.storageKey]!) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('1.x members move to encrypted storage and keep their buying power', () async {
    SharedPreferences.setMockInitialValues({'cm_rewards_state_v1': jsonEncode(v1Data)});
    final store = MemoryStore();
    final state = await RewardsState.load(store: store);
    await state.flush();

    expect(state.signedIn, isTrue);
    expect(state.profileComplete, isTrue);
    expect(state.name, 'Jordan Lee');
    // Earning doubled from 5 to 10 points per dollar, so balances double.
    expect(state.points, 6420);
    expect(state.lifetimePoints, 10800);
    expect(state.tier.label, 'Insider');
    expect(state.transactions, hasLength(2));
    expect(state.favoriteStores, {2, 4});
    expect(state.hapticsEnabled, isFalse);
    expect(state.notifyDeals || state.notifyRewards || state.notifyOrders, isFalse);
    // 1.x clipped offers by title; those can't be matched, so they're cleared.
    expect(state.clippedDeals, isEmpty);

    // The plain-text copy is gone; the encrypted copy is current.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cm_rewards_state_v1'), isNull);
    expect(saved(store)['schema'], RewardsState.schemaVersion);
    expect(saved(store)['points'], 6420);
  });

  test('migration runs once: reloading does not double points again', () async {
    SharedPreferences.setMockInitialValues({'cm_rewards_state_v1': jsonEncode(v1Data)});
    final store = MemoryStore();
    await (await RewardsState.load(store: store)).flush();
    final again = await RewardsState.load(store: store);
    expect(again.points, 6420);
  });

  test('saved state round-trips, including the wallet and active orders', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryStore();
    final first = await RewardsState.load(store: store);
    first
      ..signIn('5035550123', skipProfile: true)
      ..setHomeStore(3)
      ..toggleFavorite(5)
      ..setAvatar('🦊', 1)
      ..setSounds(false);
    final active = first.redeem(rewards.first)!;
    first.addToCart(menu.first, 0, 2);
    final order = first.placeOrder(storeNumber: 1, pickupMinutes: 10, payment: 'Apple Pay');
    await first.flush();

    final second = await RewardsState.load(store: store);
    expect(second.phoneDigits, '5035550123');
    expect(second.homeStore, 3);
    expect(second.favoriteStores, contains(5));
    expect(second.avatar, '🦊');
    expect(second.soundsEnabled, isFalse);
    expect(second.points, first.points);
    // A redeemed code must survive the app being closed.
    expect(second.wallet.single.code, active.code);
    expect(second.activeOrder?.number, order.number);
    expect(second.activeOrder?.lines.single.quantity, 2);
  });

  test('corrupt storage falls back to a fresh start instead of crashing', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await RewardsState.load(store: MemoryStore({RewardsState.storageKey: '{not json'}));
    expect(state.signedIn, isFalse);
  });
}
