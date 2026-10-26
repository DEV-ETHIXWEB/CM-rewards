import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/cm_icons.dart';

Future<void> openDirections(BuildContext context, Store store) {
  final destination = Uri.encodeComponent(sampleCatalog ? 'Center Market, ${store.city}' : store.fullAddress);
  final uri = Theme.of(context).platform == TargetPlatform.iOS
      ? Uri.parse('https://maps.apple.com/?daddr=$destination')
      : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
  return launchExternal(context, uri, 'Could not open maps on this device.');
}

Future<void> callStore(BuildContext context, Store store) {
  final phone = store.phone;
  if (phone == null) return Future.value();
  return launchExternal(context, Uri(scheme: 'tel', path: phone), "Calling isn't available on this device.");
}

enum StoreFilter {
  all('All'),
  open('Open now'),
  favorites('Favorites'),
  fuel('Fuel'),
  hotFood('Hot food'),
  allNight('24 hours'),
  ev('EV charging');

  const StoreFilter(this.label);

  final String label;

  bool matches(Store s, DateTime now, Set<int> favorites) => switch (this) {
    StoreFilter.all => true,
    StoreFilter.open => s.isOpenAt(now),
    StoreFilter.favorites => favorites.contains(s.number),
    StoreFilter.fuel => s.hasFuel,
    StoreFilter.hotFood => s.amenities.contains('Hot Food'),
    StoreFilter.allNight => s.isOpen24Hours,
    StoreFilter.ev => s.amenities.contains('EV Charging'),
  };
}

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final _search = TextEditingController();
  StoreFilter _filter = StoreFilter.all;
  bool _map = false;
  int? _selected;

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
    final now = DateTime.now();
    final query = _search.text.trim().toLowerCase();
    final results = stores.where((s) {
      final matches = query.isEmpty || '${s.name} ${s.street} ${s.fullAddress}'.toLowerCase().contains(query);
      return matches && _filter.matches(s, now, state.favoriteStores);
    }).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                reveal(
                  0,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow('50+ Oregon locations', color: c.positiveInk),
                            const SizedBox(height: 6),
                            const Text('Find a store', style: AppText.display),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: SegmentedTabs(
                          labels: const ['List', 'Map'],
                          index: _map ? 1 : 0,
                          onChanged: (i) => setState(() => _map = i == 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                reveal(
                  1,
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: c.line),
                    ),
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        hintText: 'Search by street or city',
                        hintStyle: TextStyle(color: c.hint),
                        prefixIcon: CMIcon(CMGlyph.search, color: c.muted),
                        suffixIcon: _search.text.isEmpty
                            ? IconButton(
                                tooltip: 'Stores near me',
                                icon: CMIcon(CMGlyph.locate, color: c.primaryInk),
                                onPressed: _nearMe,
                              )
                            : IconButton(tooltip: 'Clear', icon: const CMIcon(CMGlyph.close), onPressed: _search.clear),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          reveal(
            2,
            ChipFilter<StoreFilter>(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              options: [
                for (final f in StoreFilter.values)
                  (f, f == StoreFilter.favorites ? 'Favorites (${state.favoriteStores.length})' : f.label),
              ],
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _map
                  ? _mapView(results, now, state)
                  : results.isEmpty
                  ? SingleChildScrollView(
                      key: const ValueKey('empty'),
                      child: EmptyState(
                        icon: _filter == StoreFilter.favorites ? CMGlyph.heart : CMGlyph.store,
                        title: _filter == StoreFilter.favorites ? 'No favorites yet' : 'No stores found',
                        body: _filter == StoreFilter.favorites
                            ? 'Tap the heart on a store to save it here.'
                            : 'Try a different street, city or filter.',
                      ),
                    )
                  : SingleChildScrollView(
                      key: const ValueKey('list'),
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset(context)),
                      // One column on phones, pairs of cards on wide pages.
                      child: PairedList(
                        spacing: 14,
                        children: [
                          for (final (index, store) in results.indexed)
                            FadeSlideIn(
                              key: ValueKey('${_filter.name}-${store.number}'),
                              delay: Duration(milliseconds: 50 * index),
                              child: StoreCard(
                                store: store,
                                now: now,
                                favorite: state.favoriteStores.contains(store.number),
                                isHome: state.homeStore == store.number,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the map with the closest store picked.
  void _nearMe() {
    RewardsScope.read(context).haptic();
    final nearest = ([...stores]..sort((a, b) => a.distance.compareTo(b.distance))).first;
    setState(() {
      _filter = StoreFilter.all;
      _map = true;
      _selected = nearest.number;
    });
  }

  Widget _mapView(List<Store> results, DateTime now, RewardsState state) {
    final selected = results.where((s) => s.number == _selected).firstOrNull ?? results.firstOrNull;
    return Padding(
      key: const ValueKey('map'),
      padding: EdgeInsets.fromLTRB(20, 16, 20, navClearance(context)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Stack(
          children: [
            Positioned.fill(
              child: AreaMap(
                stores: results,
                selected: selected?.number,
                onSelect: (n) => setState(() => _selected = n),
              ),
            ),
            if (selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: FadeSlideIn(
                  key: ValueKey(selected.number),
                  offset: 12,
                  child: _MapStoreCard(store: selected, now: now),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A stylized map of the Salem–Keizer area. A real build would use a maps SDK.
class AreaMap extends StatelessWidget {
  const AreaMap({super.key, required this.stores, required this.selected, required this.onSelect});

  final List<Store> stores;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Leave room at the bottom for the store card.
        Offset place(Offset p) => Offset(p.dx * size.width, p.dy * (size.height - 150) + 10);
        const me = Offset(0.48, 0.62);
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter(c))),
            Positioned(left: place(me).dx - 40, top: place(me).dy - 40, child: const _MeDot()),
            for (final (i, s) in stores.indexed)
              Positioned(
                left: place(s.mapPosition).dx - 22,
                top: place(s.mapPosition).dy - 52,
                // Pins drop onto the map one after another.
                child: FadeSlideIn(
                  key: ValueKey('pin-${s.number}'),
                  delay: Duration(milliseconds: 90 * i),
                  offset: -18,
                  child: Pressable(
                    semanticLabel: s.name,
                    onTap: () => onSelect(s.number),
                    child: _Pin(number: s.number, selected: s.number == selected),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.c);

  final CMColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = c.isDark ? const Color(0xFF1E1A1C) : const Color(0xFFEFEBE4));

    // Parks.
    final park = Paint()..color = (c.isDark ? Brand.green.withValues(alpha: 0.18) : const Color(0xFFD7EBD9));
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.08, w * 0.22, h * 0.12), const Radius.circular(18)),
        park,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.62, w * 0.2, h * 0.16), const Radius.circular(18)),
        park,
      );

    // The Willamette River, winding up the west side.
    final river = Path()
      ..moveTo(w * 0.05, h)
      ..cubicTo(w * 0.25, h * 0.75, w * 0.0, h * 0.55, w * 0.12, h * 0.35)
      ..cubicTo(w * 0.22, h * 0.18, w * 0.05, h * 0.08, w * 0.15, 0);
    canvas.drawPath(
      river,
      Paint()
        ..color = c.isDark ? const Color(0xFF1B3340) : const Color(0xFFBFDDEA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );

    final road = Paint()
      ..color = c.isDark ? const Color(0xFF332B2E) : Brand.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rng = Random(4);
    for (var i = 0; i < 7; i++) {
      final y = h * (0.1 + i * 0.13) + rng.nextDouble() * 10;
      canvas.drawLine(Offset(0, y), Offset(w, y + (rng.nextDouble() - 0.5) * 40), road..strokeWidth = i.isEven ? 7 : 4);
    }
    for (var i = 0; i < 5; i++) {
      final x = w * (0.2 + i * 0.18) + rng.nextDouble() * 10;
      canvas.drawLine(Offset(x, 0), Offset(x + (rng.nextDouble() - 0.5) * 50, h), road..strokeWidth = i == 2 ? 9 : 4);
    }
    // Interstate 5, in a burgundy tint.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.9, 0)
        ..cubicTo(w * 0.8, h * 0.4, w * 0.95, h * 0.6, w * 0.85, h),
      Paint()
        ..color = Brand.burgundy.withValues(alpha: c.isDark ? 0.45 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.c != c;
}

class _Pin extends StatelessWidget {
  const _Pin({required this.number, required this.selected});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.15 : 1,
      duration: Motion.medium,
      curve: Curves.easeOutBack,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 44,
        height: 54,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Brand.burgundy : Brand.white,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? Brand.white : Brand.burgundy, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Brand.ink.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                '$number',
                style: TextStyle(
                  fontFamily: AppText.slab,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: selected ? Brand.white : Brand.burgundy,
                ),
              ),
            ),
            Container(width: 3, height: 10, color: selected ? Brand.burgundy : Brand.white),
          ],
        ),
      ),
    );
  }
}

class _MeDot extends StatefulWidget {
  const _MeDot();

  @override
  State<_MeDot> createState() => _MeDotState();
}

class _MeDotState extends State<_MeDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
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
    return Semantics(
      label: 'Your location',
      child: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 20 + 60 * _controller.value,
                height: 20 + 60 * _controller.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.green.withValues(alpha: 0.3 * (1 - _controller.value)),
                ),
              ),
              child!,
            ],
          ),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Brand.green,
              shape: BoxShape.circle,
              border: Border.all(color: Brand.white, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapStoreCard extends StatelessWidget {
  const _MapStoreCard({required this.store, required this.now});

  final Store store;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      scale: 0.98,
      onTap: () => showStoreSheet(context, store),
      child: Panel(
        padding: const EdgeInsets.all(12),
        radius: 22,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 60, height: 60, child: BrandPhoto(store.photo)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${store.street} · ${store.distanceLabel}', style: TextStyle(color: c.muted, fontSize: 13)),
                  const SizedBox(height: 6),
                  StatusPill(label: store.hoursLabel(now), positive: store.isOpenAt(now)),
                ],
              ),
            ),
            CircleIconButton(
              icon: CMGlyph.navigate,
              label: 'Directions',
              background: c.primary,
              foreground: Brand.white,
              onTap: () => openDirections(context, store),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.store, required this.favorite});

  final Store store;
  final bool favorite;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      semanticLabel: favorite ? 'Remove from favorites' : 'Add to favorites',
      scale: 0.8,
      onTap: () => RewardsScope.read(context).toggleFavorite(store.number),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: c.elevation()),
        child: AnimatedSwitcher(
          duration: Motion.medium,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: child,
          ),
          child: CMIcon(
            favorite ? CMGlyph.heartFill : CMGlyph.heart,
            key: ValueKey(favorite),
            color: favorite ? c.primaryInk : c.muted,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  const StoreCard({super.key, required this.store, required this.now, required this.favorite, this.isHome = false});

  final Store store;
  final DateTime now;
  final bool favorite;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final open = store.isOpenAt(now);
    final fuel = store.fuel;

    return Pressable(
      scale: 0.98,
      onTap: () => showStoreSheet(context, store),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: c.isDark ? Border.all(color: c.line) : null,
          boxShadow: c.elevation(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BrandPhoto(store.photo, semanticLabel: '${store.name} storefront'),
                  const Scrim(from: 0.45, opacity: 0.5),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _FavoriteButton(store: store, favorite: favorite),
                  ),
                  if (isHome)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Brand.burgundy, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CMIcon(CMGlyph.homeFill, size: 13, color: Brand.white),
                            SizedBox(width: 4),
                            Text(
                              'Home store',
                              style: TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        const CMIcon(CMGlyph.navigate, size: 15, color: Brand.white),
                        const SizedBox(width: 4),
                        Text(
                          store.distanceLabel,
                          style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (fuel != null)
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Brand.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CMIcon(CMGlyph.fuel, size: 14, color: Brand.green),
                            const SizedBox(width: 4),
                            Text(
                              formatFuel(fuel.regular),
                              style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              store.fullAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(label: open ? 'Open' : 'Closed', positive: open),
                    ],
                  ),
                  const SizedBox(height: 12),
                  EdgeFade(
                    start: false,
                    always: true,
                    width: 28,
                    child: SizedBox(
                      height: 28,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final a in store.amenities)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9),
                                decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CMIcon(amenityIcons[a] ?? CMGlyph.check, size: 14, color: c.muted),
                                    const SizedBox(width: 4),
                                    Text(
                                      a,
                                      style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.hoursLabel(now),
                          style: TextStyle(
                            color: open ? c.positiveInk : c.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (store.phone != null) ...[
                        CircleIconButton(
                          icon: CMGlyph.phone,
                          label: 'Call',
                          size: 42,
                          onTap: () => callStore(context, store),
                        ),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: () {
                            RewardsScope.read(context).haptic();
                            fireAndForget(openDirections(context, store));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Brand.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                          ),
                          icon: const CMIcon(CMGlyph.navigate, size: 19),
                          label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
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

Future<void> showStoreSheet(BuildContext context, Store store) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final now = DateTime.now();
    final open = store.isOpenAt(now);
    final isHome = state.homeStore == store.number;
    final fuel = store.fuel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BrandPhoto(store.photo, semanticLabel: '${store.name} storefront'),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _FavoriteButton(store: store, favorite: state.favoriteStores.contains(store.number)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(store.name, style: AppText.headline),
        const SizedBox(height: 4),
        Text(store.fullAddress, style: TextStyle(color: c.muted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(label: store.hoursLabel(now), positive: open),
            StatusPill(label: '${store.distanceLabel} away', positive: false, dot: false),
            if (open) StatusPill(label: store.busyLabel(now), positive: false, dot: false),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (store.phone != null) ...[
              Expanded(
                child: SecondaryButton(label: 'Call', icon: CMGlyph.phone, onPressed: () => callStore(context, store)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => openDirections(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Brand.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  icon: const CMIcon(CMGlyph.navigate),
                  label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
        if (fuel != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('Fuel prices', style: AppText.title)),
              Text('Updated 12 min ago', style: TextStyle(color: c.muted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 10),
          FuelGrid(prices: fuel, discountCents: state.tier.fuelDiscountCents),
        ],
        const SizedBox(height: 24),
        const Text('Popular times', style: AppText.title),
        const SizedBox(height: 4),
        Text(
          open ? '${store.busyLabel(now)} right now' : 'Closed right now',
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          child: BusyChart(store: store, hour: now.hour),
        ),
        const SizedBox(height: 24),
        const Text('Hours', style: AppText.title),
        const SizedBox(height: 10),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CMIcon(CMGlyph.calendar, color: c.primaryInk, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Every day', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(
                store.hoursRange,
                style: TextStyle(fontWeight: FontWeight.w800, color: c.primaryInk),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('In this store', style: AppText.title),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amenity in store.amenities)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CMIcon(amenityIcons[amenity] ?? CMGlyph.check, size: 18, color: c.positiveInk),
                    const SizedBox(width: 6),
                    Text(amenity, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: isHome ? 'Your home store' : 'Make this my home store',
          icon: isHome ? CMGlyph.homeFill : CMGlyph.home,
          tone: isHome ? ButtonTone.positive : ButtonTone.dark,
          onPressed: isHome
              ? null
              : () {
                  state.setHomeStore(store.number);
                  showToast(context, '${store.name} is now your home store', icon: CMGlyph.homeFill);
                },
        ),
      ],
    );
  });
}

class FuelGrid extends StatelessWidget {
  const FuelGrid({super.key, required this.prices, required this.discountCents});

  final FuelPrices prices;
  final int discountCents;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Row(
      children: [
        for (final (grade, tenths) in prices.grades) ...[
          if (grade != prices.grades.first.$1) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: c.line),
              ),
              child: Column(
                children: [
                  Text(
                    grade,
                    style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      formatFuel(tenths - discountCents * 10),
                      style: AppText.headline.copyWith(fontSize: 20, fontFeatures: AppText.tabular),
                    ),
                  ),
                  if (discountCents > 0)
                    Text(
                      formatFuel(tenths),
                      style: TextStyle(
                        color: c.hint,
                        fontSize: 11.5,
                        decoration: TextDecoration.lineThrough,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class BusyChart extends StatelessWidget {
  const BusyChart({super.key, required this.store, required this.hour});

  final Store store;
  final int hour;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    const from = 5;
    const to = 24;
    return Column(
      children: [
        SizedBox(
          height: 74,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var h = from; h < to; h++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: store.busyness[h] / 10),
                      duration: Duration(milliseconds: 500 + 25 * (h - from)),
                      curve: Motion.standard,
                      builder: (context, v, _) => Container(
                        height: max(4, 74 * v),
                        decoration: BoxDecoration(
                          color: h == hour ? c.primary : c.positive.withValues(alpha: c.isDark ? 0.45 : 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final h in [6, 12, 18, 23]) Text(formatHour(h), style: TextStyle(color: c.muted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

Future<void> showFuelSheet(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final withFuel = stores.where((s) => s.hasFuel).toList()
      ..sort((a, b) => a.fuel!.regular.compareTo(b.fuel!.regular));
    final discount = state.tier.fuelDiscountCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fuel near you', style: AppText.headline),
        const SizedBox(height: 4),
        Text(
          discount > 0
              ? 'Prices include your $discount¢/gal ${state.tier.label} discount.'
              : 'Reach Regular tier to save 5¢ on every gallon.',
          style: TextStyle(color: c.muted),
        ),
        const SizedBox(height: 16),
        for (final (i, s) in withFuel.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Pressable(
              scale: 0.98,
              onTap: () {
                Navigator.of(context).pop();
                fireAndForget(showStoreSheet(context, s));
              },
              child: Panel(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.name} · ${s.distanceLabel}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (i == 0) const StatusPill(label: 'Lowest', positive: true, dot: false),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FuelGrid(prices: s.fuel!, discountCents: discount),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Panel(
          color: c.positiveSoft,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CMIcon(CMGlyph.fuel, color: c.positiveInk),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Redeem ${formatNumber(rewards.firstWhere((r) => r.id == 'fuel10').points)} points for 10¢ off per gallon on your next fill.',
                  style: TextStyle(color: c.positiveInk, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  });
}
