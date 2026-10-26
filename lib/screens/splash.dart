import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    final width = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
    final photos = {brandVideoPoster, ...deals.map((d) => d.photo), ...stores.map((s) => s.photo)};
    for (final photo in photos) {
      unawaited(precacheImage(ResizeImage(AssetImage(photo), width: width), context));
    }
  }

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        final state = RewardsScope.read(context);
        final next = !state.signedIn
            ? const LoginScreen()
            : state.profileComplete
            ? const MainShell()
            : const PersonalizeScreen();
        Navigator.of(context).pushReplacement(fadeRoute<void>(next));
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The splash is always ivory, matching the native launch screen, so opening
  // the app is one continuous brand moment in light and dark mode alike.
  static final _brandTheme = buildTheme(CMColors.light);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
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
                            child: const Hero(tag: 'cm-logo', child: CMLogo(height: 150)),
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
              child: Opacity(
                opacity: _tagline.value,
                child: Center(child: MarketDots(color: c.positive, size: 7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
