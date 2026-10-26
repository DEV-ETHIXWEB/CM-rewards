import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import 'storage.dart';

class RewardsState extends ChangeNotifier {
  RewardsState([this._store]) {
    _applyDefaults();
  }

  /// Loads saved member data from encrypted storage, migrating anything an
  /// older version of the app left in plain preferences.
  static Future<RewardsState> load({KeyValueStore store = const SecureStore()}) async {
    String? raw;
    try {
      raw = await store.read(storageKey);
    } catch (_) {
      // Unreadable keychain or keystore entry: start fresh rather than crash.
      raw = null;
    }
    SharedPreferences? prefs;
    if (raw == null) {
      try {
        prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(_plainStorageKey) ?? prefs.getString(_legacyStorageKey);
      } catch (_) {
        prefs = null;
      }
    }
    final state = RewardsState(store).._restore(raw);
    if (prefs != null && raw != null) {
      // Moved into encrypted storage; remove the plain-text copies.
      await prefs.remove(_plainStorageKey);
      await prefs.remove(_legacyStorageKey);
    }
    return state;
  }

  static const storageKey = 'cm_rewards_state';

  /// Plain-preferences keys used before data moved to encrypted storage:
  /// 2.0 previews, and version 1.x.
  static const _plainStorageKey = 'cm_rewards_state_v2';
  static const _legacyStorageKey = 'cm_rewards_state_v1';

  /// Bump when the saved shape changes, and teach [_restore] the old shape.
  /// 3: points economy moved from 5 to 10 points per dollar.
  static const schemaVersion = 3;

  /// Gift limits, so a typo can't send away a whole balance.
  static const giftMinimum = 50;
  static const giftMaximum = 5000;

  /// Points each side gets when a referred friend makes a first purchase.
  static const referralBonus = 50;
  static const pointsPerDollar = 10;
  static const firstOrderBonus = 250;

  final KeyValueStore? _store;
  final _rng = Random.secure();
  Future<void> _lastWrite = Future.value();

  /// Appearance lives in its own notifier so changing points or favorites
  /// doesn't rebuild the whole MaterialApp.
  final appearance = ValueNotifier<ThemeMode>(ThemeMode.system);

  ThemeMode get themeMode => appearance.value;
  set themeMode(ThemeMode mode) => appearance.value = mode;

  late bool signedIn;
  late bool profileComplete;
  late String name;
  late String email;
  late String phoneDigits;
  late DateTime memberSince;
  DateTime? birthday;
  late int points;
  late int lifetimePoints;
  late int visits;
  late int redeemedCount;
  late int savedCents;
  late bool hapticsEnabled;
  late bool soundsEnabled;

  /// A character emoji for the profile picture, or empty for initials.
  late String avatar;
  late int avatarColor;
  late bool notifyDeals;
  late bool notifyRewards;
  late bool notifyOrders;
  late bool personalizedOffers;
  late bool locationAccess;
  late int homeStore;
  late String defaultPayment;
  late Set<String> interests;
  late Set<int> favoriteStores;
  late Set<String> clippedDeals;
  late Set<String> readNotifications;
  late Set<String> dismissedNotifications;
  late List<PointsTransaction> transactions;
  int? _pickupStore;
  final List<Order> orders = [];
  final List<CartLine> cart = [];
  final List<ActiveReward> _wallet = [];

  // ─── Derived ────────────────────────────────────────────────────────────────

  String get phone => formatPhone(phoneDigits);
  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initials =>
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase();
  String get memberId {
    final d = phoneDigits.padLeft(10, '0');
    return 'CM ${d.substring(0, 4)} ${d.substring(4, 7)} ${d.substring(7)}';
  }

  String get referralCode {
    final letters = firstName.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    return '${letters.isEmpty ? 'CM' : letters.substring(0, min(6, letters.length))}$referralBonus';
  }

  Tier get tier => Tier.forPoints(lifetimePoints);
  Store get home => storeByNumber(homeStore);

  /// The cheapest reward the member can't afford yet, or the priciest one.
  Reward get nextReward {
    final sorted = [...rewards]..sort((a, b) => a.points.compareTo(b.points));
    return sorted.firstWhere((r) => r.points > points, orElse: () => sorted.last);
  }

  int get unlockedCount => rewards.where((r) => r.points <= points).length;

  List<AppNotification> get notifications =>
      notificationFeed.where((n) => !dismissedNotifications.contains(n.id)).toList();

  int get unreadCount => notifications.where((n) => !readNotifications.contains(n.id)).length;

  List<ActiveReward> get wallet {
    final now = DateTime.now();
    _wallet.removeWhere((r) => r.expiresAt.isBefore(now));
    return List.unmodifiable(_wallet);
  }

  /// Days this week (Mon = 0) with at least one visit.
  Set<int> get visitDaysThisWeek {
    final start = startOfWeek(DateTime.now());
    return transactions.where((t) => t.isVisit && !t.date.isBefore(start)).map((t) => t.date.weekday - 1).toSet();
  }

  /// Consecutive weeks, ending this week or last, with at least one visit.
  int get streakWeeks {
    var week = startOfWeek(DateTime.now());
    bool visitedIn(DateTime start) {
      final end = start.add(const Duration(days: 7));
      return transactions.any((t) => t.isVisit && !t.date.isBefore(start) && t.date.isBefore(end));
    }

    if (!visitedIn(week)) week = week.subtract(const Duration(days: 7));
    var streak = 0;
    while (visitedIn(week)) {
      streak++;
      week = week.subtract(const Duration(days: 7));
    }
    return streak;
  }

  Order? get activeOrder {
    for (final order in orders) {
      if (!order.pickedUp) return order;
    }
    return null;
  }

  /// Where Order Ahead pickups go: the chosen store, else home if it takes orders.
  int get pickupStore {
    final chosen = _pickupStore;
    if (chosen != null) return chosen;
    return home.amenities.contains('Order Ahead')
        ? homeStore
        : stores.firstWhere((s) => s.amenities.contains('Order Ahead')).number;
  }

  bool get hasOrdered => transactions.any((t) => t.type == TxType.order);

  int get cartCount => cart.fold(0, (sum, l) => sum + l.quantity);
  int get cartSubtotal => cart.fold(0, (sum, l) => sum + l.totalCents);
  int pointsFor(int cents) => (cents / 100 * pointsPerDollar * tier.multiplier).round();

  // ─── Defaults & persistence ─────────────────────────────────────────────────

  void _applyDefaults() {
    final now = DateTime.now();
    DateTime ago(int days, int hour) {
      final d = now.subtract(Duration(days: days));
      return days == 0 ? now.subtract(const Duration(hours: 1)) : DateTime(d.year, d.month, d.day, hour);
    }

    signedIn = false;
    profileComplete = false;
    name = 'Akash';
    email = '';
    phoneDigits = '5551234567';
    memberSince = DateTime(2024, 3, 14);
    birthday = null;
    points = 2340;
    lifetimePoints = 4860;
    visits = 24;
    redeemedCount = 3;
    savedCents = 4275;
    themeMode = ThemeMode.system;
    hapticsEnabled = true;
    soundsEnabled = true;
    avatar = '';
    avatarColor = 0;
    notifyDeals = true;
    notifyRewards = true;
    notifyOrders = true;
    personalizedOffers = true;
    locationAccess = true;
    homeStore = 1;
    defaultPayment = paymentMethods.first.id;
    interests = {'coffee', 'pizza'};
    favoriteStores = {1};
    clippedDeals = {};
    readNotifications = {'n4', 'n5'};
    dismissedNotifications = {};
    _pickupStore = null;
    orders.clear();
    cart.clear();
    _wallet.clear();
    transactions = [
      PointsTransaction(
        type: TxType.purchase,
        title: 'In-store purchase',
        detail: '#1 Main St · \$8.75',
        points: 100,
        date: ago(0, 0),
      ),
      PointsTransaction(
        type: TxType.redeem,
        title: 'Redeemed Free Coffee',
        detail: '#1 Main St',
        points: -600,
        date: ago(1, 8),
      ),
      PointsTransaction(
        type: TxType.order,
        title: 'Order Ahead pickup',
        detail: '#2 Oak Ave · \$12.40',
        points: 150,
        date: ago(2, 17),
      ),
      PointsTransaction(
        type: TxType.challenge,
        title: 'Weekly challenge complete',
        detail: 'Visited 3 times this week',
        points: 200,
        date: ago(3, 12),
      ),
      PointsTransaction(
        type: TxType.purchase,
        title: 'In-store purchase',
        detail: '#3 Elm Blvd · \$6.20',
        points: 60,
        date: ago(5, 21),
      ),
      PointsTransaction(
        type: TxType.bonus,
        title: 'Double Points Weekend',
        detail: 'Bonus on your Saturday visit',
        points: 120,
        date: ago(6, 14),
      ),
      PointsTransaction(
        type: TxType.purchase,
        title: 'Fuel & snacks',
        detail: '#2 Oak Ave · \$41.15',
        points: 410,
        date: ago(8, 18),
      ),
      PointsTransaction(
        type: TxType.redeem,
        title: 'Redeemed Free Icee',
        detail: '#4 River Rd',
        points: -650,
        date: ago(10, 15),
      ),
      PointsTransaction(
        type: TxType.referral,
        title: 'Friend joined CM Rewards',
        detail: 'Referral bonus',
        points: 50,
        date: ago(11, 10),
      ),
      PointsTransaction(
        type: TxType.purchase,
        title: 'In-store purchase',
        detail: '#4 River Rd · \$15.90',
        points: 160,
        date: ago(13, 19),
      ),
      PointsTransaction(
        type: TxType.purchase,
        title: 'In-store purchase',
        detail: '#1 Main St · \$4.50',
        points: 50,
        date: ago(16, 7),
      ),
      PointsTransaction(
        type: TxType.bonus,
        title: 'Birthday bonus',
        detail: 'Happy birthday from Center Market',
        points: 500,
        date: ago(19, 9),
      ),
      PointsTransaction(
        type: TxType.purchase,
        title: 'In-store purchase',
        detail: '#5 Park Lane · \$9.99',
        points: 100,
        date: ago(22, 16),
      ),
      PointsTransaction(
        type: TxType.redeem,
        title: 'Redeemed 1L Cool Drink',
        detail: '#2 Oak Ave',
        points: -500,
        date: ago(26, 13),
      ),
      PointsTransaction(
        type: TxType.purchase,
        title: 'In-store purchase',
        detail: '#2 Oak Ave · \$31.20',
        points: 310,
        date: ago(30, 18),
      ),
      PointsTransaction(
        type: TxType.bonus,
        title: 'Welcome bonus',
        detail: 'Thanks for joining CM Rewards',
        points: 400,
        date: ago(35, 11),
      ),
    ];
  }

  void _restore(String? raw) {
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final schema = json['schema'] as int? ?? 1;
      signedIn = json['signedIn'] as bool;
      profileComplete = json['profileComplete'] as bool? ?? true;
      name = json['name'] as String;
      email = json['email'] as String? ?? '';
      phoneDigits = json['phone'] as String;
      final bday = json['birthday'] as String?;
      birthday = bday == null ? null : DateTime.parse(bday);
      points = json['points'] as int;
      lifetimePoints = json['lifetime'] as int;
      visits = json['visits'] as int;
      redeemedCount = json['redeemed'] as int;
      savedCents = json['saved'] as int? ?? savedCents;
      themeMode = ThemeMode.values.byName(json['theme'] as String? ?? 'system');
      hapticsEnabled = json['haptics'] as bool;
      soundsEnabled = json['sounds'] as bool? ?? true;
      avatar = json['avatar'] as String? ?? '';
      avatarColor = json['avatarColor'] as int? ?? 0;
      // 1.x had a single notifications switch.
      notifyDeals = json['notifyDeals'] as bool? ?? json['notifications'] as bool? ?? true;
      notifyRewards = json['notifyRewards'] as bool? ?? json['notifications'] as bool? ?? true;
      notifyOrders = json['notifyOrders'] as bool? ?? json['notifications'] as bool? ?? true;
      personalizedOffers = json['personalized'] as bool? ?? true;
      locationAccess = json['location'] as bool? ?? true;
      homeStore = json['homeStore'] as int? ?? 1;
      defaultPayment = json['payment'] as String? ?? defaultPayment;
      interests = (json['interests'] as List<dynamic>? ?? []).cast<String>().toSet();
      transactions = (json['transactions'] as List<dynamic>)
          .map((e) => PointsTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      favoriteStores = (json['favorites'] as List<dynamic>).cast<int>().toSet();
      clippedDeals = (json['clipped'] as List<dynamic>).cast<String>().toSet();
      readNotifications = (json['read'] as List<dynamic>).cast<String>().toSet();
      dismissedNotifications = (json['dismissed'] as List<dynamic>).cast<String>().toSet();
      _wallet
        ..clear()
        ..addAll(
          (json['wallet'] as List<dynamic>? ?? []).map((e) => _walletFromJson(e as Map<String, dynamic>)).nonNulls,
        );
      orders
        ..clear()
        ..addAll(
          (json['orders'] as List<dynamic>? ?? []).map((e) => _orderFromJson(e as Map<String, dynamic>)).nonNulls,
        );
      if (schema < schemaVersion) _migrate(from: schema);
    } catch (_) {
      _applyDefaults();
    }
  }

  void _migrate({required int from}) {
    if (from < 2) {
      // 1.x clipped offers by title, which can't be matched; 1.x members
      // already set up their profile.
      clippedDeals = {};
      profileComplete = true;
    }
    if (from < 3) {
      // Earning doubled from 5 to 10 points per dollar, so balances double
      // too. Members keep the same buying power.
      points *= 2;
      lifetimePoints *= 2;
    }
    _commit();
  }

  Map<String, Object> _walletToJson(ActiveReward r) => {
    'reward': r.reward.id,
    'code': r.code,
    'expires': r.expiresAt.toIso8601String(),
  };

  ActiveReward? _walletFromJson(Map<String, dynamic> json) {
    final reward = rewards.where((r) => r.id == json['reward']).firstOrNull;
    if (reward == null) return null;
    return ActiveReward(reward, json['code'] as String, DateTime.parse(json['expires'] as String));
  }

  Map<String, Object> _orderToJson(Order o) => {
    'number': o.number,
    'lines': [
      for (final l in o.lines) {'item': l.item.id, 'size': l.sizeIndex, 'qty': l.quantity},
    ],
    'store': o.storeNumber,
    'placed': o.placedAt.toIso8601String(),
    'ready': o.readyAt.toIso8601String(),
    'subtotal': o.subtotalCents,
    'tax': o.taxCents,
    'points': o.pointsEarned,
    'payment': o.payment,
    'pickedUp': o.pickedUp,
  };

  Order? _orderFromJson(Map<String, dynamic> json) {
    final lines = <CartLine>[];
    for (final raw in json['lines'] as List<dynamic>) {
      final line = raw as Map<String, dynamic>;
      final item = menu.where((m) => m.id == line['item']).firstOrNull;
      if (item == null) continue;
      lines.add(CartLine(item, line['size'] as int, line['qty'] as int));
    }
    if (lines.isEmpty) return null;
    return Order(
      number: json['number'] as int,
      lines: lines,
      storeNumber: json['store'] as int,
      placedAt: DateTime.parse(json['placed'] as String),
      readyAt: DateTime.parse(json['ready'] as String),
      subtotalCents: json['subtotal'] as int,
      taxCents: json['tax'] as int,
      pointsEarned: json['points'] as int,
      payment: json['payment'] as String,
      pickedUp: json['pickedUp'] as bool,
    );
  }

  void _commit() {
    notifyListeners();
    final store = _store;
    if (store == null) return;
    final data = jsonEncode({
      'schema': schemaVersion,
      'signedIn': signedIn,
      'profileComplete': profileComplete,
      'name': name,
      'email': email,
      'phone': phoneDigits,
      'birthday': birthday?.toIso8601String(),
      'points': points,
      'lifetime': lifetimePoints,
      'visits': visits,
      'redeemed': redeemedCount,
      'saved': savedCents,
      'theme': themeMode.name,
      'haptics': hapticsEnabled,
      'sounds': soundsEnabled,
      'avatar': avatar,
      'avatarColor': avatarColor,
      'notifyDeals': notifyDeals,
      'notifyRewards': notifyRewards,
      'notifyOrders': notifyOrders,
      'personalized': personalizedOffers,
      'location': locationAccess,
      'homeStore': homeStore,
      'payment': defaultPayment,
      'interests': interests.toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'favorites': favoriteStores.toList(),
      'clipped': clippedDeals.toList(),
      'read': readNotifications.toList(),
      'dismissed': dismissedNotifications.toList(),
      'wallet': wallet.map(_walletToJson).toList(),
      // Keep active orders and a short pickup history.
      'orders': orders.take(10).map(_orderToJson).toList(),
    });
    // Chain writes so a slow write can never land after a newer one.
    _lastWrite = _lastWrite.then((_) => store.write(storageKey, data)).catchError((Object _) {});
  }

  /// Completes once everything committed so far is on disk.
  Future<void> flush() => _lastWrite;

  // ─── Actions ────────────────────────────────────────────────────────────────

  /// Tap feedback: a haptic tick and the system click sound, each when on.
  void haptic({bool strong = false}) {
    if (soundsEnabled) unawaited(SystemSound.play(SystemSoundType.click));
    if (!hapticsEnabled) return;
    unawaited(strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick());
  }

  void signIn(String digits, {bool skipProfile = false}) {
    signedIn = true;
    phoneDigits = digits;
    if (skipProfile) profileComplete = true;
    _commit();
  }

  void completeProfile({required String name, required Set<String> interests, required int homeStore}) {
    if (name.trim().isNotEmpty) setName(name);
    this.interests = interests;
    this.homeStore = homeStore;
    favoriteStores.add(homeStore);
    profileComplete = true;
    _commit();
  }

  void signOut() {
    _applyDefaults();
    _commit();
  }

  ActiveReward? redeem(Reward reward) {
    if (points < reward.points) return null;
    points -= reward.points;
    redeemedCount++;
    transactions.insert(
      0,
      PointsTransaction(
        type: TxType.redeem,
        title: 'Redeemed ${reward.name}',
        detail: 'Show code to cashier',
        points: -reward.points,
        date: DateTime.now(),
      ),
    );
    final active = ActiveReward(
      reward,
      'CM${100000 + _rng.nextInt(900000)}${reward.points}',
      DateTime.now().add(const Duration(minutes: 15)),
    );
    _wallet.insert(0, active);
    _commit();
    return active;
  }

  /// Demo helper: pretends the member's pass was scanned at checkout.
  (int, Store) simulatePurchase() {
    final store = stores[_rng.nextInt(stores.length)];
    final cents = 400 + _rng.nextInt(2600);
    var earned = pointsFor(cents);
    final bonus = deals.where((d) => clippedDeals.contains(d.id)).fold(0, (sum, d) => sum + d.bonusPoints);
    earned += bonus;
    points += earned;
    lifetimePoints += earned;
    visits++;
    if (bonus > 0) savedCents += 150;
    clippedDeals.clear();
    transactions.insert(
      0,
      PointsTransaction(
        type: TxType.purchase,
        title: bonus > 0 ? 'Purchase with offers' : 'In-store purchase',
        detail: '#${store.number} ${store.street} · ${formatMoney(cents)}',
        points: earned,
        date: DateTime.now(),
      ),
    );
    _commit();
    return (earned, store);
  }

  /// Sends points to a friend. Returns false for an invalid number, your own
  /// number, an amount outside the limits, or a balance that's too low.
  bool giftPoints(String digits, int amount) {
    if (!isValidUsPhone(digits) || digits == phoneDigits) return false;
    if (amount < giftMinimum || amount > giftMaximum || amount > points) return false;
    points -= amount;
    transactions.insert(
      0,
      PointsTransaction(
        type: TxType.gift,
        title: 'Gifted points',
        detail: 'To +1 ${formatPhone(digits)}',
        points: -amount,
        date: DateTime.now(),
      ),
    );
    _commit();
    return true;
  }

  // Cart & orders ---------------------------------------------------------------

  void addToCart(MenuItem item, int sizeIndex, int quantity) {
    final existing = cart.where((l) => l.sameAs(item, sizeIndex)).firstOrNull;
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      cart.add(CartLine(item, sizeIndex, quantity));
    }
    notifyListeners();
  }

  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      cart.remove(line);
    } else {
      line.quantity = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  Order placeOrder({required int storeNumber, required int pickupMinutes, required String payment}) {
    final now = DateTime.now();
    final subtotal = cartSubtotal;
    final firstOrder = !hasOrdered;
    final earned = pointsFor(subtotal) + (firstOrder ? firstOrderBonus : 0);
    final order = Order(
      number: 100 + _rng.nextInt(900),
      lines: [...cart],
      storeNumber: storeNumber,
      placedAt: now,
      // Demo orders get ready quickly so the tracker is fun to watch.
      readyAt: now.add(Duration(seconds: pickupMinutes <= 10 ? 45 : pickupMinutes * 6)),
      subtotalCents: subtotal,
      taxCents: (subtotal * oregonTaxRate).round(),
      pointsEarned: earned,
      payment: payment,
    );
    orders.insert(0, order);
    cart.clear();
    points += earned;
    lifetimePoints += earned;
    visits++;
    final store = storeByNumber(storeNumber);
    transactions.insert(
      0,
      PointsTransaction(
        type: TxType.order,
        title: 'Order Ahead #${order.number}',
        detail: '#${store.number} ${store.street} · ${formatMoney(order.totalCents)}',
        points: earned,
        date: now,
      ),
    );
    _commit();
    return order;
  }

  void markPickedUp(Order order) {
    order.pickedUp = true;
    _commit();
  }

  // Profile & preferences -------------------------------------------------------

  void setName(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return;
    name = trimmed.length > maxNameLength ? trimmed.substring(0, maxNameLength) : trimmed;
    _commit();
  }

  /// Saves a valid email, or clears it when empty. Returns false if invalid.
  bool setEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !isValidEmail(trimmed)) return false;
    email = trimmed;
    _commit();
    return true;
  }

  void setBirthday(DateTime? value) {
    birthday = value;
    _commit();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _commit();
  }

  void setHomeStore(int number) {
    homeStore = number;
    _commit();
  }

  void setPickupStore(int number) {
    _pickupStore = number;
    notifyListeners();
  }

  void setDefaultPayment(String id) {
    defaultPayment = id;
    _commit();
  }

  void toggleInterest(String id) {
    if (!interests.remove(id)) interests.add(id);
    _commit();
  }

  void toggleFavorite(int storeNumber) {
    if (!favoriteStores.remove(storeNumber)) favoriteStores.add(storeNumber);
    _commit();
  }

  void toggleDeal(String id) {
    if (!clippedDeals.remove(id)) clippedDeals.add(id);
    _commit();
  }

  void markRead(String id) {
    if (readNotifications.add(id)) _commit();
  }

  void markAllRead() {
    readNotifications.addAll(notificationFeed.map((n) => n.id));
    _commit();
  }

  void dismissNotification(String id) {
    dismissedNotifications.add(id);
    _commit();
  }

  void setSounds(bool enabled) {
    soundsEnabled = enabled;
    _commit();
  }

  void setAvatar(String emoji, int color) {
    avatar = emoji;
    avatarColor = color;
    _commit();
  }

  void setHaptics(bool enabled) {
    hapticsEnabled = enabled;
    _commit();
  }

  void setNotify(NoticeKind kind, bool enabled) {
    switch (kind) {
      case NoticeKind.deals || NoticeKind.stores:
        notifyDeals = enabled;
      case NoticeKind.rewards:
        notifyRewards = enabled;
      case NoticeKind.orders:
        notifyOrders = enabled;
    }
    _commit();
  }

  void setPersonalizedOffers(bool enabled) {
    personalizedOffers = enabled;
    _commit();
  }

  void setLocationAccess(bool enabled) {
    locationAccess = enabled;
    _commit();
  }
}

const maxNameLength = 40;

/// North American numbers: area code and exchange can't start with 0 or 1.
bool isValidUsPhone(String digits) => RegExp(r'^[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits);

bool isValidEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(value);

class RewardsScope extends InheritedNotifier<RewardsState> {
  const RewardsScope({super.key, required RewardsState state, required super.child}) : super(notifier: state);

  /// Reads the state and rebuilds the caller when it changes.
  static RewardsState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<RewardsScope>()!.notifier!;

  /// Reads the state without subscribing, for use in callbacks.
  static RewardsState read(BuildContext context) => context.getInheritedWidgetOfExactType<RewardsScope>()!.notifier!;
}
