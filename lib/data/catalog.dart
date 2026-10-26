import 'package:flutter/material.dart';

import 'models.dart';
import '../widgets/cm_icons.dart';

const _photos = 'assets/photos';
const logoAsset = 'assets/images/logo.png';
const brandVideo = 'assets/media/cm_store.mp4';
const brandVideoPoster = '$_photos/video_poster.jpg';
const aerialPhoto = '$_photos/aerial.jpg';
const anniversaryPhoto = '$_photos/anniversary.jpg';
const interiorPhoto = '$_photos/interior.jpg';
const aislePhoto = '$_photos/aisle.jpg';
const storeExteriorPhoto = '$_photos/store_exterior.jpg';
const ownersPhoto = '$_photos/owners.jpg';

// ─── Offers ───────────────────────────────────────────────────────────────────

const deals = [
  Deal(
    id: 'drumsticks',
    emoji: '🍗',
    title: 'Chicken Drumsticks',
    price: '2 for \$3',
    tag: 'Hot Food',
    description: 'Crispy, golden drumsticks fresh from our hot case.',
    photo: '$_photos/chicken.jpg',
    endsIn: 'Ends Sunday',
    bonusPoints: 50,
    forYou: true,
  ),
  Deal(
    id: 'icee',
    emoji: '🧊',
    title: 'Icee Any Size',
    price: '\$1.49',
    tag: 'Frozen',
    description: 'Any size, any flavor. Mix them if you dare.',
    photo: '$_photos/icee.jpg',
    endsIn: 'Today only',
    forYou: true,
  ),
  Deal(
    id: 'cheetos',
    emoji: '🔥',
    title: "Flamin' Hot Cheetos",
    price: 'Buy 1 Get 1',
    tag: 'Snacks',
    description: 'Grab a bag and the second one is on us.',
    photo: '$_photos/hot_snacks.jpg',
    endsIn: '3 days left',
    bonusPoints: 25,
  ),
  Deal(
    id: 'pizza',
    emoji: '🍕',
    title: 'Fresh Pizza Slice',
    price: '\$2.00',
    tag: 'Hot Food',
    description: 'Baked in store all day. Pepperoni, cheese or supreme.',
    photo: '$_photos/hot_deli_sign.jpg',
    endsIn: 'Ends Friday',
    bonusPoints: 30,
    forYou: true,
  ),
  Deal(
    id: 'beer',
    emoji: '🍺',
    title: 'Beer Cave Special',
    price: '6-pack deals',
    tag: '21+ only',
    description: 'Ice cold 6-packs at special prices. Valid ID required.',
    photo: '$_photos/beer_cave.jpg',
    endsIn: 'This weekend',
  ),
];

// ─── Rewards ──────────────────────────────────────────────────────────────────

// Every reward starts at 500 points ($50 spent at 10 points per $1).
const rewards = [
  Reward(
    'cooldrink',
    '🥤',
    '1L Cool Drink',
    500,
    'Any 1-liter soda or iced tea from the cooler',
    RewardCategory.drinks,
  ),
  Reward('coffee', '☕', 'Free Coffee', 600, 'Any size hot or iced coffee', RewardCategory.drinks),
  Reward('icee', '🧊', 'Free Icee', 650, 'Any size, any flavor', RewardCategory.drinks, photo: '$_photos/icee.jpg'),
  Reward(
    'chips',
    '🥔',
    'Kettle Chips',
    700,
    'Any bag of Kettle Brand chips',
    RewardCategory.food,
    photo: '$_photos/kettle_hot.jpg',
  ),
  Reward('fuel10', '⛽', '10¢ off per gallon', 750, 'Up to 20 gallons on your next fill', RewardCategory.fuel),
  Reward(
    'pizza',
    '🍕',
    'Free Pizza Slice',
    900,
    'One fresh slice, any topping',
    RewardCategory.food,
    photo: '$_photos/hot_deli_sign.jpg',
  ),
  Reward(
    'tenders',
    '🍗',
    'Chicken Tenders',
    1500,
    'A 3-piece tenders basket',
    RewardCategory.food,
    photo: '$_photos/chicken.jpg',
  ),
  Reward('fuel25', '⛽', '25¢ off per gallon', 1800, 'Up to 20 gallons on your next fill', RewardCategory.fuel),
  Reward(
    'raffle',
    '🎟️',
    'Monthly Raffle Entry',
    2500,
    "One entry into this month's prize draw",
    RewardCategory.extras,
  ),
  Reward('tumbler', '🥤', 'CM Steel Tumbler', 4000, 'Free refills for life on fountain drinks', RewardCategory.extras),
];

const challenges = [
  Challenge('🏃', 'Visit 3 times this week', 2, 3, 200, '3 days left'),
  Challenge('🍕', 'Grab 2 pizza slices', 1, 2, 150, '5 days left'),
  Challenge('🧾', 'Spend \$25 this week', 18, 25, 100, '3 days left', prefix: '\$'),
  Challenge('📱', 'Try Order Ahead', 0, 1, 250, 'This month'),
  Challenge('🌅', 'Morning coffee run', 0, 1, 50, 'Before 10 AM'),
];

// ─── Stores ───────────────────────────────────────────────────────────────────

// Typical busy curve for a neighborhood store, by hour.
const _commuter = [0, 0, 0, 0, 0, 1, 4, 7, 8, 5, 4, 5, 7, 6, 4, 5, 7, 9, 8, 6, 5, 4, 2, 1];
const _lateNight = [3, 2, 2, 1, 1, 2, 4, 6, 6, 4, 4, 5, 6, 5, 5, 6, 8, 9, 9, 8, 7, 6, 5, 4];
const _quiet = [0, 0, 0, 0, 0, 0, 2, 4, 5, 3, 3, 4, 5, 4, 3, 3, 5, 6, 5, 4, 3, 1, 0, 0];

/// The stores, menu, offers and rewards below are sample content for demos.
/// While this is true the app doesn't point at street addresses: Directions
/// searches Maps for Center Market in the store's city instead. Set it to
/// false when the real catalog replaces this one.
const sampleCatalog = true;

const stores = [
  Store(
    number: 1,
    street: 'Main St',
    address: '1420 Main St',
    city: 'Salem, OR 97301',
    distance: 0.8,
    opens: 6,
    closes: 23,
    amenities: ['Hot Food', 'Pizza', 'Coffee', 'ATM', 'Order Ahead'],
    photo: '$_photos/store_exterior.jpg',
    mapPosition: Offset(0.42, 0.52),
    busyness: _commuter,
  ),
  Store(
    number: 2,
    street: 'Oak Ave',
    address: '2315 Oak Ave NE',
    city: 'Salem, OR 97301',
    distance: 1.4,
    opens: 5,
    closes: 24,
    amenities: ['Hot Food', 'Fuel', 'Beer Cave', 'Lottery', 'Icee', 'Order Ahead'],
    photo: '$_photos/grand_opening.jpg',
    mapPosition: Offset(0.68, 0.36),
    busyness: _commuter,
    fuel: FuelPrices(3899, 4199, 4499),
  ),
  Store(
    number: 3,
    street: 'Elm Blvd',
    address: '880 Elm Blvd',
    city: 'Keizer, OR 97303',
    distance: 2.3,
    opens: 0,
    closes: 24,
    amenities: ['Hot Food', 'Pizza', 'Fuel', 'EV Charging', 'ATM', 'Lottery', 'Order Ahead'],
    photo: aerialPhoto,
    mapPosition: Offset(0.3, 0.2),
    busyness: _lateNight,
    fuel: FuelPrices(3859, 4159, 4459, diesel: 4299),
  ),
  Store(
    number: 4,
    street: 'River Rd',
    address: '4567 River Rd N',
    city: 'Keizer, OR 97303',
    distance: 3.1,
    opens: 6,
    closes: 22,
    amenities: ['Coffee', 'Fuel', 'Beer Cave', 'Icee'],
    photo: brandVideoPoster,
    mapPosition: Offset(0.16, 0.42),
    busyness: _quiet,
    fuel: FuelPrices(3879, 4179, 4479, diesel: 4319),
  ),
  Store(
    number: 5,
    street: 'Park Lane',
    address: '310 Park Ln SE',
    city: 'Salem, OR 97302',
    distance: 4.6,
    opens: 7,
    closes: 21,
    amenities: ['Pizza', 'Coffee', 'Lottery'],
    photo: interiorPhoto,
    mapPosition: Offset(0.74, 0.78),
    busyness: _quiet,
  ),
];

Store storeByNumber(int number) => stores.firstWhere((s) => s.number == number, orElse: () => stores.first);

// ─── Order ahead menu ─────────────────────────────────────────────────────────

const _sizes = [('Small', 0), ('Medium', 50), ('Large', 100)];

const menu = [
  MenuItem(
    id: 'tenders',
    name: 'Chicken Tenders Basket',
    description: '3 hand-breaded tenders with jojos and your choice of sauce.',
    cents: 699,
    category: MenuCategory.hotFood,
    emoji: '🍗',
    calories: 820,
    photo: '$_photos/chicken.jpg',
    popular: true,
  ),
  MenuItem(
    id: 'drumsticks',
    name: 'Drumsticks (2 pc)',
    description: 'Crispy, golden and fresh from the hot case.',
    cents: 300,
    category: MenuCategory.hotFood,
    emoji: '🍗',
    calories: 440,
    photo: '$_photos/chicken.jpg',
  ),
  MenuItem(
    id: 'jojos',
    name: 'Jojos',
    description: 'Seasoned potato wedges, an Oregon classic.',
    cents: 249,
    category: MenuCategory.hotFood,
    emoji: '🥔',
    calories: 380,
    sizes: [('Regular', 0), ('Large', 150)],
  ),
  MenuItem(
    id: 'burrito',
    name: 'Breakfast Burrito',
    description: 'Egg, sausage, cheddar and potato in a warm tortilla.',
    cents: 449,
    category: MenuCategory.hotFood,
    emoji: '🌯',
    calories: 610,
    popular: true,
  ),
  MenuItem(
    id: 'pepperoni',
    name: 'Pepperoni Slice',
    description: 'Baked in store all day with whole-milk mozzarella.',
    cents: 299,
    category: MenuCategory.pizza,
    emoji: '🍕',
    calories: 330,
    photo: '$_photos/hot_deli_sign.jpg',
    popular: true,
  ),
  MenuItem(
    id: 'cheese',
    name: 'Cheese Slice',
    description: 'Simple and perfect. Extra cheese, no apologies.',
    cents: 249,
    category: MenuCategory.pizza,
    emoji: '🧀',
    calories: 290,
  ),
  MenuItem(
    id: 'whole',
    name: 'Whole 16" Pizza',
    description: 'Feeds the crew. Pepperoni, cheese or supreme.',
    cents: 1499,
    category: MenuCategory.pizza,
    emoji: '🍕',
    calories: 2640,
    sizes: [('Cheese', 0), ('Pepperoni', 200), ('Supreme', 400)],
  ),
  MenuItem(
    id: 'drip',
    name: 'Fresh Drip Coffee',
    description: 'Locally roasted, brewed every 30 minutes.',
    cents: 179,
    category: MenuCategory.coffee,
    emoji: '☕',
    calories: 5,
    sizes: _sizes,
    popular: true,
  ),
  MenuItem(
    id: 'latte',
    name: 'Iced Vanilla Latte',
    description: 'Espresso, cold milk and real vanilla over ice.',
    cents: 349,
    category: MenuCategory.coffee,
    emoji: '🧋',
    calories: 210,
    sizes: _sizes,
  ),
  MenuItem(
    id: 'cappuccino',
    name: 'Cappuccino',
    description: 'Velvety foam, double shot.',
    cents: 299,
    category: MenuCategory.coffee,
    emoji: '☕',
    calories: 130,
    sizes: _sizes,
  ),
  MenuItem(
    id: 'icee',
    name: 'Icee',
    description: 'Cherry, blue raspberry, or mix them.',
    cents: 149,
    category: MenuCategory.frozen,
    emoji: '🧊',
    calories: 180,
    photo: '$_photos/icee.jpg',
    sizes: _sizes,
  ),
  MenuItem(
    id: 'shake',
    name: 'Huckleberry Shake',
    description: 'Real Pacific Northwest huckleberries.',
    cents: 399,
    category: MenuCategory.frozen,
    emoji: '🥤',
    calories: 540,
  ),
  MenuItem(
    id: 'cheetos',
    name: "Flamin' Hot Cheetos",
    description: 'Party size. Buy 1, get 1 this week.',
    cents: 449,
    category: MenuCategory.snacks,
    emoji: '🔥',
    calories: 160,
    photo: '$_photos/hot_snacks.jpg',
  ),
  MenuItem(
    id: 'kettle',
    name: 'Kettle Krinkle Cut Chips',
    description: 'Dill pickle or habanero lime. Thick, crunchy, kettle-cooked.',
    cents: 349,
    category: MenuCategory.snacks,
    emoji: '🥔',
    calories: 150,
    photo: '$_photos/kettle_dill.jpg',
    sizes: [('Dill Pickle', 0), ('Habanero Lime', 0)],
  ),
  MenuItem(
    id: 'jerky',
    name: 'Oregon Beef Jerky',
    description: 'Small-batch, peppered, made in Tillamook.',
    cents: 699,
    category: MenuCategory.snacks,
    emoji: '🥩',
    calories: 240,
  ),
];

const paymentMethods = [
  PaymentMethod('wallet', 'Apple Pay', 'Default on this device', CMGlyph.device),
  PaymentMethod('visa', 'Visa •• 4242', 'Expires 08/29', CMGlyph.card),
  PaymentMethod('store', 'Pay at pickup', 'Cash or card at the counter', CMGlyph.storeFill),
];

const oregonTaxRate = 0.0; // Oregon has no sales tax.

// ─── Notifications ────────────────────────────────────────────────────────────

const notificationFeed = [
  AppNotification(
    'n1',
    NoticeKind.rewards,
    'Double Points Weekend',
    'Earn 2× points on every purchase this Saturday and Sunday.',
    Duration(hours: 2),
  ),
  AppNotification(
    'n2',
    NoticeKind.rewards,
    "You're almost there",
    'Just a little more to unlock your next reward. Keep going!',
    Duration(hours: 5),
  ),
  AppNotification(
    'n3',
    NoticeKind.deals,
    'New deal just dropped',
    'Icee any size for \$1.49, today only.',
    Duration(hours: 20),
  ),
  AppNotification(
    'n6',
    NoticeKind.orders,
    'Order Ahead is here',
    'Skip the line. Order hot food and coffee from the app, pick it up in minutes.',
    Duration(days: 2),
  ),
  AppNotification(
    'n4',
    NoticeKind.rewards,
    'Challenge complete!',
    'You earned 200 bonus points for visiting 3 times this week.',
    Duration(days: 3),
  ),
  AppNotification(
    'n5',
    NoticeKind.stores,
    'Now open: Center Market #5',
    'Our Park Lane store is open daily from 7 AM to 9 PM.',
    Duration(days: 6),
  ),
];

const interestOptions = [
  ('coffee', '☕', 'Coffee'),
  ('hot', '🍗', 'Hot food'),
  ('pizza', '🍕', 'Pizza'),
  ('fuel', '⛽', 'Fuel'),
  ('snacks', '🥨', 'Snacks'),
  ('frozen', '🧊', 'Icee & frozen'),
  ('energy', '⚡', 'Energy drinks'),
  ('beer', '🍺', 'Beer & wine'),
];
