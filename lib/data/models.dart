import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/cm_icons.dart';

// ─── Offers & rewards ─────────────────────────────────────────────────────────

class Deal {
  const Deal({
    required this.id,
    required this.emoji,
    required this.title,
    required this.price,
    required this.tag,
    required this.description,
    required this.photo,
    required this.endsIn,
    this.bonusPoints = 0,
    this.forYou = false,
  });

  final String id;
  final String emoji;
  final String title;
  final String price;
  final String tag;
  final String description;
  final String photo;
  final String endsIn;

  /// Extra points when the clipped offer is used.
  final int bonusPoints;

  /// Picked from the member's habits.
  final bool forYou;
}

enum RewardCategory {
  drinks('Drinks', CMGlyph.cup),
  food('Food', CMGlyph.food),
  fuel('Fuel', CMGlyph.fuel),
  extras('Extras', CMGlyph.sparkle);

  const RewardCategory(this.label, this.icon);

  final String label;
  final CMGlyph icon;
}

class Reward {
  const Reward(this.id, this.emoji, this.name, this.points, this.description, this.category, {this.photo});

  final String id;
  final String emoji;
  final String name;
  final int points;
  final String description;
  final RewardCategory category;
  final String? photo;
}

class ActiveReward {
  const ActiveReward(this.reward, this.code, this.expiresAt);

  final Reward reward;
  final String code;
  final DateTime expiresAt;
}

class Challenge {
  const Challenge(this.emoji, this.title, this.progress, this.goal, this.reward, this.endsIn, {this.prefix = ''});

  final String emoji;
  final String title;
  final int progress;
  final int goal;
  final int reward;
  final String endsIn;
  final String prefix;

  bool get complete => progress >= goal;
}

// ─── Tiers ────────────────────────────────────────────────────────────────────

enum Tier {
  neighbor('Neighbor', 0, 1.0, Brand.green, [
    (CMGlyph.star, '10 points for every \$1'),
    (CMGlyph.cake, 'Birthday treat on us'),
    (CMGlyph.tag, 'Members-only weekly offers'),
  ]),
  regular('Regular', 2500, 1.25, Brand.burgundy, [
    (CMGlyph.bolt, '1.25× points on every purchase'),
    (CMGlyph.fuel, '5¢ off every gallon'),
    (CMGlyph.cup, 'Free coffee refill, every visit'),
  ]),
  insider('Insider', 6000, 1.5, Brand.champagneDeep, [
    (CMGlyph.bolt, '1.5× points on every purchase'),
    (CMGlyph.fuel, '10¢ off every gallon'),
    (CMGlyph.timer, 'Priority pickup on Order Ahead'),
    (CMGlyph.calendarCheck, 'Early access to new deals'),
  ]);

  const Tier(this.label, this.threshold, this.multiplier, this.color, this.perks);

  final String label;
  final int threshold;
  final double multiplier;
  final Color color;
  final List<(CMGlyph, String)> perks;

  static Tier forPoints(int lifetimePoints) => values.lastWhere((t) => lifetimePoints >= t.threshold);

  Tier? get next => index + 1 < values.length ? values[index + 1] : null;

  /// Points per dollar at this tier: "10", "12.5", "15".
  String get earnRate {
    final rate = 10 * multiplier;
    return rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';
  }

  int get fuelDiscountCents => switch (this) {
    Tier.neighbor => 0,
    Tier.regular => 5,
    Tier.insider => 10,
  };
}

// ─── Stores ───────────────────────────────────────────────────────────────────

const amenityIcons = {
  'Hot Food': CMGlyph.food,
  'Pizza': CMGlyph.pizza,
  'Coffee': CMGlyph.cup,
  'ATM': CMGlyph.cash,
  'Beer Cave': CMGlyph.beer,
  'Lottery': CMGlyph.ticket,
  'Icee': CMGlyph.icee,
  'Fuel': CMGlyph.fuel,
  'EV Charging': CMGlyph.ev,
  'Order Ahead': CMGlyph.bagFill,
};

class FuelPrices {
  const FuelPrices(this.regular, this.midgrade, this.premium, {this.diesel});

  /// Prices in tenths of a cent, like the pump: 3899 → $3.899.
  final int regular;
  final int midgrade;
  final int premium;
  final int? diesel;

  List<(String, int)> get grades => [
    ('Regular', regular),
    ('Mid', midgrade),
    ('Premium', premium),
    if (diesel != null) ('Diesel', diesel!),
  ];
}

/// Pump-style price, dropping the tenth of a cent: 3899 → "$3.89".
String formatFuel(int tenths) {
  final cents = tenths ~/ 10;
  return '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
}

class Store {
  const Store({
    required this.number,
    required this.street,
    required this.address,
    required this.city,
    this.phone,
    required this.distance,
    required this.opens,
    required this.closes,
    required this.amenities,
    required this.photo,
    required this.mapPosition,
    required this.busyness,
    this.fuel,
  });

  final int number;
  final String street;
  final String address;
  final String city;

  /// Null when the store's number isn't known; the app then offers no Call button.
  final String? phone;
  final double distance;

  /// Opening and closing hour (24h clock). `closes: 24` means midnight.
  final int opens;
  final int closes;
  final List<String> amenities;
  final String photo;

  /// Position on the stylized area map, from 0 to 1 on each axis.
  final Offset mapPosition;

  /// How busy the store usually is for each hour of the day, 0 to 10.
  final List<int> busyness;
  final FuelPrices? fuel;

  String get name => 'Center Market #$number';
  String get fullAddress => '$address, $city';
  bool get isOpen24Hours => opens == 0 && closes == 24;
  bool get hasFuel => fuel != null;
  String get hoursRange => isOpen24Hours ? 'Open 24 hours' : '${formatHour(opens)} – ${formatHour(closes)}';
  String get distanceLabel => '${distance.toStringAsFixed(1)} mi';

  bool isOpenAt(DateTime time) {
    if (isOpen24Hours) return true;
    final hour = time.hour + time.minute / 60;
    return hour >= opens && hour < closes;
  }

  String hoursLabel(DateTime now) {
    if (isOpen24Hours) return 'Open 24 hours';
    if (isOpenAt(now)) return 'Open until ${formatHour(closes)}';
    return 'Opens ${formatHour(opens)}';
  }

  String busyLabel(DateTime now) {
    if (!isOpenAt(now)) return 'Closed now';
    final level = busyness[now.hour];
    if (level <= 3) return 'Not busy';
    if (level <= 6) return 'A little busy';
    return 'Busy';
  }
}

// ─── Order ahead ──────────────────────────────────────────────────────────────

enum MenuCategory {
  hotFood('Hot Food', '🍗'),
  pizza('Pizza', '🍕'),
  coffee('Coffee', '☕'),
  frozen('Frozen', '🧊'),
  snacks('Snacks', '🥨');

  const MenuCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cents,
    required this.category,
    required this.emoji,
    required this.calories,
    this.photo,
    this.sizes = const [],
    this.popular = false,
  });

  final String id;
  final String name;
  final String description;
  final int cents;
  final MenuCategory category;
  final String emoji;
  final int calories;
  final String? photo;

  /// Size name and the extra price for it.
  final List<(String, int)> sizes;
  final bool popular;
}

class CartLine {
  CartLine(this.item, this.sizeIndex, this.quantity);

  final MenuItem item;
  final int sizeIndex;
  int quantity;

  String? get sizeLabel => item.sizes.isEmpty ? null : item.sizes[sizeIndex].$1;
  int get unitCents => item.cents + (item.sizes.isEmpty ? 0 : item.sizes[sizeIndex].$2);
  int get totalCents => unitCents * quantity;

  bool sameAs(MenuItem other, int size) => item.id == other.id && sizeIndex == size;
}

enum OrderStage {
  received('Order received', 'The store has your order', CMGlyph.receipt),
  preparing('Being prepared', 'Our team is making it fresh', CMGlyph.pot),
  ready('Ready for pickup', 'Head to the counter and say your name', CMGlyph.bagFill),
  pickedUp('Picked up', 'Enjoy!', CMGlyph.checkCircle);

  const OrderStage(this.title, this.detail, this.icon);

  final String title;
  final String detail;
  final CMGlyph icon;
}

class Order {
  Order({
    required this.number,
    required this.lines,
    required this.storeNumber,
    required this.placedAt,
    required this.readyAt,
    required this.subtotalCents,
    required this.taxCents,
    required this.pointsEarned,
    required this.payment,
    this.pickedUp = false,
  });

  final int number;
  final List<CartLine> lines;
  final int storeNumber;
  final DateTime placedAt;
  final DateTime readyAt;
  final int subtotalCents;
  final int taxCents;
  final int pointsEarned;
  final String payment;
  bool pickedUp;

  int get totalCents => subtotalCents + taxCents;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  OrderStage stageAt(DateTime now) {
    if (pickedUp) return OrderStage.pickedUp;
    if (!now.isBefore(readyAt)) return OrderStage.ready;
    final prepStart = placedAt.add(readyAt.difference(placedAt) * 0.2);
    return now.isBefore(prepStart) ? OrderStage.received : OrderStage.preparing;
  }

  double progressAt(DateTime now) {
    if (pickedUp || !now.isBefore(readyAt)) return 1;
    final total = readyAt.difference(placedAt).inMilliseconds;
    return (now.difference(placedAt).inMilliseconds / total).clamp(0.0, 1.0);
  }
}

class PaymentMethod {
  const PaymentMethod(this.id, this.label, this.detail, this.icon);

  final String id;
  final String label;
  final String detail;
  final CMGlyph icon;
}

// ─── Activity & notifications ─────────────────────────────────────────────────

enum TxType { purchase, redeem, bonus, referral, challenge, order, gift }

class PointsTransaction {
  const PointsTransaction({
    required this.type,
    required this.title,
    required this.detail,
    required this.points,
    required this.date,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) => PointsTransaction(
    type: TxType.values.byName(json['type'] as String),
    title: json['title'] as String,
    detail: json['detail'] as String,
    points: json['points'] as int,
    date: DateTime.parse(json['date'] as String),
  );

  final TxType type;
  final String title;
  final String detail;
  final int points;
  final DateTime date;

  bool get isEarn => points >= 0;

  /// Counts as a store visit for streaks and challenges.
  bool get isVisit => type == TxType.purchase || type == TxType.order;

  CMGlyph get icon => switch (type) {
    TxType.purchase => CMGlyph.basket,
    TxType.redeem => CMGlyph.giftFill,
    TxType.bonus => CMGlyph.sparkle,
    TxType.referral => CMGlyph.people,
    TxType.challenge => CMGlyph.trophy,
    TxType.order => CMGlyph.bagFill,
    TxType.gift => CMGlyph.handHeart,
  };

  Map<String, Object> toJson() => {
    'type': type.name,
    'title': title,
    'detail': detail,
    'points': points,
    'date': date.toIso8601String(),
  };
}

enum NoticeKind {
  deals('Deals', CMGlyph.tag),
  rewards('Rewards', CMGlyph.star),
  orders('Orders', CMGlyph.bagFill),
  stores('Stores', CMGlyph.storeFill);

  const NoticeKind(this.label, this.icon);

  final String label;
  final CMGlyph icon;
}

class AppNotification {
  const AppNotification(this.id, this.kind, this.title, this.body, this.age);

  final String id;
  final NoticeKind kind;
  final String title;
  final String body;
  final Duration age;
}
