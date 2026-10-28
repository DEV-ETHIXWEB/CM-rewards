import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/splash_handoff.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
    animationBehavior: AnimationBehavior.preserve,
  );

  // The logo's swooshes draw themselves in, then the real logo takes over.
  late final Animation<double> _arcs = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.42, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.32, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 0.78, curve: Motion.standard),
  );

  // Taken once, before the first frame, so the dots carry on from the web
  // page's loader in step.
  final double _dotsPhase = loaderDotsPhase();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_start());
  }

  /// Plays the animation once the logo is decoded, so it never fades in as an
  /// empty space, then fetches the photos the next screens open on.
  Future<void> _start() async {
    final dark = switch (RewardsScope.read(context).themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final logo = precacheImage(CMLogo.provider(context, height: _logoHeight), context);
    // The sign-in screen's logo, and Home's in dark mode, are smaller decodes.
    unawaited(precacheImage(CMLogo.provider(context, height: 40), context));
    if (dark) unawaited(precacheImage(CMLogo.provider(context, height: 38, onDark: true), context));
    // On a slow connection the splash goes ahead after a moment rather than
    // holding the dots; the logo then appears as soon as it arrives.
    await logo.timeout(const Duration(milliseconds: 1200), onTimeout: () {});
    if (!mounted) return;
    _controller.forward();
    if (kIsWeb) await _warmPhotos();
  }

  /// In a browser, assets come over the network: fetch the photos one at a
  /// time behind the splash so they're cached when their screens decode them,
  /// without competing with the logo or the animation.
  Future<void> _warmPhotos() async {
    final photos = {brandVideoPoster, ...deals.map((d) => d.photo), ...stores.map((s) => s.photo)};
    for (final photo in photos) {
      if (!mounted) return;
      try {
        await rootBundle.load(photo);
      } catch (_) {
        // A missing photo shows its placeholder; nothing to do here.
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      final state = RewardsScope.read(context);
      final next = !state.signedIn
          ? const LoginScreen()
          : state.profileComplete
          ? const MainShell()
          : const PersonalizeScreen();
      Navigator.of(context).pushReplacement(fadeRoute<void>(next));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The splash is always ivory, matching the native launch screen, so opening
  // the app is one continuous brand moment in light and dark mode alike.
  static final _brandTheme = buildTheme(CMColors.light);

  static const _logoHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.withBrowserColor(Brand.ivory),
      child: Theme(
        data: _brandTheme,
        child: Builder(builder: _build),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.cm;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 1 - _logo.value,
                          child: OrbitArcs(progress: _arcs.value),
                        ),
                        Opacity(
                          opacity: _logo.value,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * _logo.value,
                            child: const Hero(
                              tag: 'cm-logo',
                              child: CMLogo(height: _logoHeight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: _tagline.value,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - _tagline.value)),
                      child: Column(
                        children: [
                          Eyebrow("Oregon's Neighborhood Market", color: c.positiveInk),
                          const SizedBox(height: 8),
                          Text(
                            'Always close. Always convenient.',
                            style: AppText.headline.copyWith(fontSize: 21, color: c.primaryInk),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 48,
              // On from the first frame: they continue the loading dots.
              child: Center(
                child: MarketDots(color: c.positive, size: 7, phase: _dotsPhase),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
