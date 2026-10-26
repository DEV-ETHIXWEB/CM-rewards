import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/codes.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'stores.dart';
import '../widgets/cm_icons.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _search = TextEditingController();
  MenuCategory? _category;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final store = storeByNumber(state.pickupStore);
    final query = _search.text.trim().toLowerCase();
    final items = menu.where((m) {
      final matches = query.isEmpty || '${m.name} ${m.description}'.toLowerCase().contains(query);
      return matches && (_category == null || m.category == _category);
    }).toList();
    final groups = [
      for (final category in MenuCategory.values)
        if (items.any((m) => m.category == category)) (category, items.where((m) => m.category == category).toList()),
    ];

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      reveal(0, Eyebrow('Order ahead', color: c.positiveInk)),
                      const SizedBox(height: 6),
                      reveal(0, const Text('Hot, fresh,\nready when you are.', style: AppText.display)),
                      const SizedBox(height: 16),
                      reveal(1, _PickupChip(store: store)),
                      const SizedBox(height: 14),
                      reveal(2, _SearchField(controller: _search, hint: 'Search tenders, pizza, lattes…')),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: reveal(
                  3,
                  ChipFilter<MenuCategory?>(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    options: [
                      (null, 'All'),
                      for (final category in MenuCategory.values) (category, '${category.emoji}  ${category.label}'),
                    ],
                    selected: _category,
                    onSelected: (value) => setState(() => _category = value),
                  ),
                ),
              ),
              if (_category == null && query.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: reveal(4, _PromoBanner(tier: state.tier, firstOrder: !state.hasOrdered)),
                  ),
                ),
              if (groups.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: CMGlyph.search,
                    title: 'Nothing matches',
                    body: 'Try “coffee”, “pizza” or “tenders”.',
                  ),
                ),
              for (final (category, list) in groups) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    child: Text('${category.emoji}  ${category.label}', style: AppText.title),
                  ),
                ),
                // One column on phones, pairs of rows on wide pages.
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: PairedList(
                      spacing: 10,
                      children: [
                        for (final (index, item) in list.indexed)
                          FadeSlideIn(
                            key: ValueKey('${_category?.name}-${item.id}'),
                            delay: Duration(milliseconds: 40 * index),
                            child: _MenuRow(item: item),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(child: SizedBox(height: bottomInset(context) + (state.cartCount > 0 ? 70 : 0))),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: navClearance(context),
          child: Center(
            child: ConstrainedBox(
              // Narrower than sheets, so the checkout sheet always covers it.
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedSwitcher(
                duration: Motion.medium,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: state.cartCount == 0 ? const SizedBox.shrink() : const CartBar(key: ValueKey('cart')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.line),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          hintText: hint,
          hintStyle: TextStyle(color: c.hint),
          prefixIcon: CMIcon(CMGlyph.search, color: c.muted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(tooltip: 'Clear', icon: const CMIcon(CMGlyph.close), onPressed: controller.clear),
        ),
      ),
    );
  }
}

class _PickupChip extends StatelessWidget {
  const _PickupChip({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final open = store.isOpenAt(DateTime.now());
    return Pressable(
      scale: 0.98,
      onTap: () => _pickStore(context),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        radius: 20,
        child: Row(
          children: [
            IconTile(icon: CMGlyph.storeFill, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup at ${store.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    open
                        ? '${store.street} · Ready in about 10 min'
                        : '${store.street} · ${store.hoursLabel(DateTime.now())}',
                    style: TextStyle(color: open ? c.positiveInk : c.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            CMIcon(CMGlyph.unfold, color: c.muted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStore(BuildContext context) {
    return showAppSheet<void>(context, (context) {
      final c = context.cm;
      final state = RewardsScope.of(context);
      final now = DateTime.now();
      final ordering = stores.where((s) => s.amenities.contains('Order Ahead'));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pickup store', style: AppText.headline),
          const SizedBox(height: 4),
          Text('These stores take Order Ahead.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 16),
          for (final s in ordering)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Pressable(
                scale: 0.98,
                onTap: () {
                  state.setPickupStore(s.number);
                  Navigator.of(context).pop();
                },
                child: Panel(
                  padding: const EdgeInsets.all(14),
                  radius: 20,
                  color: state.pickupStore == s.number ? c.primarySoft : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${s.address} · ${s.distanceLabel}', style: TextStyle(color: c.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      StatusPill(label: s.isOpenAt(now) ? 'Open' : 'Closed', positive: s.isOpenAt(now)),
                      if (state.pickupStore == s.number) ...[
                        const SizedBox(width: 8),
                        CMIcon(CMGlyph.checkCircle, color: c.primaryInk),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.tier, required this.firstOrder});

  final Tier tier;
  final bool firstOrder;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Stack(
          children: [
            const Positioned.fill(child: BrandPhoto('assets/photos/hot_deli_sign.jpg', alignment: Alignment(0, -0.2))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // Solid behind the words, easing off toward the photo on the right.
                    stops: const [0, 0.55, 1],
                    colors: [
                      Brand.burgundyDeep.withValues(alpha: 0.97),
                      Brand.burgundyDeep.withValues(alpha: 0.82),
                      Brand.burgundy.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Eyebrow('Skip the line', color: Brand.greenBright),
                  const SizedBox(height: 6),
                  Text(
                    firstOrder
                        ? 'First order?\n+${RewardsState.firstOrderBonus} bonus points'
                        : 'Ready in about\n10 minutes',
                    style: AppText.headline.copyWith(color: Brand.white, fontSize: 23),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plus ${tier.earnRate} pts per \$1, as always.',
                    style: TextStyle(color: Brand.white.withValues(alpha: 0.8), fontSize: 13),
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

/// A photo of the item, or its emoji on a soft brand tint.
class MenuThumb extends StatelessWidget {
  const MenuThumb({super.key, required this.item, this.height = 84, this.width, this.radius = 18});

  final MenuItem item;
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final photo = item.photo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: photo != null
            ? BrandPhoto(photo, semanticLabel: item.name)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.primarySoft, c.positiveSoft],
                  ),
                ),
                child: Center(
                  child: Text(item.emoji, style: TextStyle(fontSize: height * 0.42)),
                ),
              ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final inCart = state.cart.where((l) => l.item.id == item.id).fold(0, (sum, l) => sum + l.quantity);
    return Pressable(
      scale: 0.98,
      onTap: () => showMenuItemSheet(context, item),
      child: Panel(
        padding: const EdgeInsets.all(10),
        radius: 22,
        child: Row(
          children: [
            MenuThumb(item: item, height: 88, width: 88),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      if (item.popular) ...[
                        const SizedBox(width: 6),
                        CMIcon(CMGlyph.flame, size: 16, color: c.primaryInk),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.muted, fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formatMoney(item.cents),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: AppText.tabular),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${item.calories} cal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: inCart > 0 ? c.positive : c.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: inCart > 0
                  ? Text(
                      '$inCart',
                      style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w800),
                    )
                  : const CMIcon(CMGlyph.plus, color: Brand.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showMenuItemSheet(BuildContext context, MenuItem item) {
  var size = 0;
  var quantity = 1;
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.read(context);
    return StatefulBuilder(
      builder: (context, setState) {
        final unit = item.cents + (item.sizes.isEmpty ? 0 : item.sizes[size].$2);
        final total = unit * quantity;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuThumb(item: item, height: 210, radius: 26),
            const SizedBox(height: 18),
            Text(item.name, style: AppText.headline),
            const SizedBox(height: 6),
            Text(item.description, style: TextStyle(color: c.muted, height: 1.45)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                StatusPill(label: '${item.calories} cal', positive: false, dot: false),
                PointsBadge(state.pointsFor(total)),
              ],
            ),
            if (item.sizes.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('Choose one', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < item.sizes.length; i++)
                    Pressable(
                      semanticLabel: item.sizes[i].$1,
                      onTap: () => setState(() => size = i),
                      child: AnimatedContainer(
                        duration: Motion.medium,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: size == i ? c.primarySoft : c.surface,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          border: Border.all(color: size == i ? c.primaryInk : c.line, width: size == i ? 1.6 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              item.sizes[i].$1,
                              style: TextStyle(fontWeight: FontWeight.w800, color: size == i ? c.primaryInk : c.ink),
                            ),
                            Text(
                              item.sizes[i].$2 == 0 ? 'Included' : '+${formatMoney(item.sizes[i].$2)}',
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                QuantityStepper(value: quantity, min: 1, onChanged: (v) => setState(() => quantity = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Add to bag',
                    trailing: Text(formatMoney(total), style: const TextStyle(fontFeatures: AppText.tabular)),
                    onPressed: () {
                      // The cart bar sliding in is the confirmation; a toast would cover it.
                      state.addToCart(item, size, quantity);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  });
}

class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = RewardsScope.of(context);
    return Pressable(
      scale: 0.98,
      semanticLabel: 'View bag',
      onTap: () => showCheckoutSheet(context),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Brand.green,
          borderRadius: BorderRadius.circular(Radii.xl),
          boxShadow: [
            BoxShadow(color: Brand.greenDeep.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Brand.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Text(
                '${state.cartCount}',
                style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'View bag',
                style: TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Text(
              formatMoney(state.cartSubtotal),
              style: const TextStyle(
                color: Brand.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                fontFeatures: AppText.tabular,
              ),
            ),
            const SizedBox(width: 8),
            const CMIcon(CMGlyph.arrowRight, color: Brand.white),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

Future<void> showCheckoutSheet(BuildContext context) {
  var pickup = 0;
  const pickupOptions = [(10, 'ASAP'), (20, '20 min'), (30, '30 min')];
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final store = storeByNumber(state.pickupStore);
    if (state.cart.isEmpty) {
      return EmptyState(
        icon: CMGlyph.bag,
        title: 'Your bag is empty',
        body: 'Add something tasty from the menu.',
        action: SecondaryButton(
          label: 'Back to menu',
          icon: CMGlyph.food,
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }
    return StatefulBuilder(
      builder: (context, setState) {
        final subtotal = state.cartSubtotal;
        final tax = (subtotal * oregonTaxRate).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Your bag', style: AppText.headline)),
                TextButton(
                  onPressed: () {
                    state.clearCart();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: c.muted),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < state.cart.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: c.line),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          MenuThumb(item: state.cart[i].item, height: 48, width: 48, radius: 14),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.cart[i].item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  [?state.cart[i].sizeLabel, formatMoney(state.cart[i].totalCents)].join(' · '),
                                  style: TextStyle(color: c.muted, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          QuantityStepper(
                            compact: true,
                            value: state.cart[i].quantity,
                            onChanged: (v) {
                              final closing = v == 0 && state.cart.length == 1;
                              state.setQuantity(state.cart[i], v);
                              if (closing) Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pickup', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Panel(
              padding: const EdgeInsets.all(14),
              radius: 20,
              child: Row(
                children: [
                  IconTile(icon: CMGlyph.storeFill, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(store.fullAddress, style: TextStyle(color: c.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SegmentedTabs(
              labels: [for (final (_, label) in pickupOptions) label],
              index: pickup,
              onChanged: (i) => setState(() => pickup = i),
            ),
            const SizedBox(height: 20),
            const Text('Payment', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ListGroup(
              children: [
                for (final method in state.availablePaymentMethods)
                  ListRow(
                    icon: method.icon,
                    title: method.label,
                    subtitle: method.detail,
                    onTap: () => state.setDefaultPayment(method.id),
                    trailing: CMIcon(
                      state.payment.id == method.id ? CMGlyph.radioOn : CMGlyph.radioOff,
                      color: state.payment.id == method.id ? c.primaryInk : c.hint,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _line(c, 'Subtotal', formatMoney(subtotal)),
            const SizedBox(height: 6),
            _line(c, 'Sales tax', tax == 0 ? 'None in Oregon' : formatMoney(tax)),
            const SizedBox(height: 6),
            _line(
              c,
              'Points you’ll earn',
              '+${formatNumber(state.pointsFor(subtotal) + (state.hasOrdered ? 0 : RewardsState.firstOrderBonus))} pts',
              color: c.positiveInk,
            ),
            Divider(height: 26, color: c.line),
            _line(c, 'Total', formatMoney(subtotal + tax), bold: true),
            const SizedBox(height: 20),
            // Never take an order no store will receive.
            if (!state.canPlaceOrders) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(Radii.md)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CMIcon(CMGlyph.info, size: 20, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ordering in the app isn’t connected to our stores yet. Order at the counter and '
                        'show your member pass to earn points.',
                        style: TextStyle(color: c.muted, fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            PrimaryButton(
              label: state.canPlaceOrders ? 'Place order' : 'Order Ahead opens soon',
              trailing: state.canPlaceOrders
                  ? Text(formatMoney(subtotal + tax), style: const TextStyle(fontFeatures: AppText.tabular))
                  : null,
              onPressed: !state.canPlaceOrders
                  ? null
                  : () {
                      final method = state.payment;
                      final order = state.placeOrder(
                        storeNumber: store.number,
                        pickupMinutes: pickupOptions[pickup].$1,
                        payment: method.label,
                      );
                      state.haptic(strong: true);
                      Navigator.of(context).pop();
                      fireAndForget(push<void>(context, OrderTrackerScreen(order: order, celebrate: true)));
                    },
            ),
          ],
        );
      },
    );
  });
}

Widget _line(CMColors c, String label, String value, {Color? color, bool bold = false}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: bold ? c.ink : c.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          fontSize: bold ? 18 : 14,
          color: color ?? c.ink,
          fontFeatures: AppText.tabular,
        ),
      ),
    ],
  );
}

// ─── Order tracker ────────────────────────────────────────────────────────────

class OrderTrackerScreen extends StatelessWidget {
  const OrderTrackerScreen({super.key, required this.order, this.celebrate = false});

  final Order order;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final store = storeByNumber(order.storeNumber);

    return Scaffold(
      appBar: ContentAppBar(AppBar(title: Text('Order #${order.number}'))),
      body: ContentWidth(
        child: Stack(
          children: [
            TickBuilder(
              builder: (context) {
                final now = DateTime.now();
                final stage = order.stageAt(now);
                final ready = stage.index >= OrderStage.ready.index;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    BurgundySurface(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox.expand(
                                        child: CircularProgressIndicator(
                                          value: order.progressAt(now),
                                          strokeWidth: 5,
                                          strokeCap: StrokeCap.round,
                                          color: Brand.greenBright,
                                          backgroundColor: Brand.white.withValues(alpha: 0.18),
                                        ),
                                      ),
                                      CMIcon(stage.icon, color: Brand.white, size: 28),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stage.title,
                                        style: AppText.headline.copyWith(color: Brand.white, fontSize: 24),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ready
                                            ? stage.detail
                                            : 'Ready at ${formatClock(order.readyAt)} · ${formatCountdown(order.readyAt.difference(now))}',
                                        style: TextStyle(
                                          color: Brand.white.withValues(alpha: 0.8),
                                          fontFeatures: AppText.tabular,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                for (final s in OrderStage.values) ...[
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: s.index <= stage.index
                                            ? Brand.greenBright
                                            : Brand.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                  if (s != OrderStage.values.last) const SizedBox(width: 6),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Panel(
                      child: Column(
                        children: [
                          for (final s in OrderStage.values)
                            _StageRow(stage: s, current: stage, last: s == OrderStage.values.last),
                        ],
                      ),
                    ),
                    if (stage == OrderStage.ready) ...[
                      const SizedBox(height: 16),
                      Panel(
                        color: c.positiveSoft,
                        child: Column(
                          children: [
                            Text(
                              'Show this at the counter',
                              style: TextStyle(color: c.positiveInk, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Brand.white,
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                              child: SizedBox(
                                width: 130,
                                height: 130,
                                child: CustomPaint(painter: QrPainter(seed: order.number * 7919)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: "I've picked it up",
                              icon: CMGlyph.check,
                              tone: ButtonTone.positive,
                              onPressed: () {
                                state.markPickedUp(order);
                                showToast(context, 'Enjoy! +${order.pointsEarned} points added.', icon: CMGlyph.star);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Panel(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(width: 56, height: 56, child: BrandPhoto(store.photo)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(store.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text(store.fullAddress, style: TextStyle(color: c.muted, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          CircleIconButton(
                            icon: CMGlyph.navigate,
                            label: 'Directions',
                            onTap: () => openDirections(context, store),
                          ),
                          const SizedBox(width: 8),
                          CircleIconButton(
                            icon: CMGlyph.phone,
                            label: 'Call store',
                            onTap: () => callStore(context, store),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Receipt', style: AppText.title),
                          const SizedBox(height: 12),
                          for (final line in order.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text(
                                    '${line.quantity}×',
                                    style: TextStyle(color: c.muted, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text([line.item.name, ?line.sizeLabel].join(' · '))),
                                  Text(
                                    formatMoney(line.totalCents),
                                    style: const TextStyle(fontFeatures: AppText.tabular),
                                  ),
                                ],
                              ),
                            ),
                          Divider(height: 20, color: c.line),
                          _line(c, 'Paid with ${order.payment}', formatMoney(order.totalCents), bold: true),
                          const SizedBox(height: 6),
                          _line(c, 'Points earned', '+${order.pointsEarned} pts', color: c.positiveInk),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (celebrate && !MediaQuery.disableAnimationsOf(context)) const Positioned.fill(child: ConfettiBurst()),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.current, required this.last});

  final OrderStage stage;
  final OrderStage current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final done = stage.index < current.index;
    final active = stage == current;
    final color = done || active ? c.positive : c.faint;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (active && stage != OrderStage.pickedUp) const _Pulse(),
                  AnimatedContainer(
                    duration: Motion.medium,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done ? c.positive : (active ? c.positiveSoft : c.faint),
                      shape: BoxShape.circle,
                      border: active ? Border.all(color: c.positive, width: 2) : null,
                    ),
                    child: done ? const CMIcon(CMGlyph.check, size: 16, color: Brand.white) : null,
                  ),
                ],
              ),
              if (!last) Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18, top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: done || active ? c.ink : c.muted),
                  ),
                  if (active) ...[
                    const SizedBox(height: 2),
                    Text(stage.detail, style: TextStyle(color: c.muted, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft ring that breathes out from the current order step.
class _Pulse extends StatefulWidget {
  const _Pulse();

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.cm.positive;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Motion.standard.transform(_controller.value);
        return Container(
          width: 28 + 18 * t,
          height: 28 + 18 * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.28 * (1 - t)),
          ),
        );
      },
    );
  }
}
