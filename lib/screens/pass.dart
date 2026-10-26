import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
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
import 'home.dart';
import '../widgets/cm_icons.dart';

void showMemberPass(BuildContext context) {
  fireAndForget(
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 480),
        reverseTransitionDuration: Motion.medium,
        pageBuilder: (context, animation, secondaryAnimation) => const MemberPassScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Motion.standard);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
  );
}

class MemberPassScreen extends StatefulWidget {
  const MemberPassScreen({super.key});

  @override
  State<MemberPassScreen> createState() => _MemberPassScreenState();
}

class _MemberPassScreenState extends State<MemberPassScreen> {
  static const _rotation = 30;

  bool _barcode = false;
  (int, Store)? _earned;
  bool _scanning = false;

  Future<void> _simulateScan() async {
    final state = RewardsScope.read(context);
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final result = state.simulatePurchase();
    state.haptic(strong: true);
    setState(() {
      _scanning = false;
      _earned = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = RewardsScope.of(context);
    final clipped = deals.where((d) => state.clippedDeals.contains(d.id)).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Brand.burgundyDeep,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.1,
                    colors: [Brand.burgundyBright.withValues(alpha: 0.9), Brand.burgundyDeep],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: -120,
              bottom: -60,
              width: 420,
              height: 320,
              child: OrbitArcs(opacity: 0.08, colors: [Brand.white, Brand.white, Brand.white]),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const CMIcon(CMGlyph.close, color: Brand.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Member pass',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ContentWidth(
                      maxWidth: 460,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                        child: AnimatedSwitcher(
                          duration: Motion.slow,
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.94, end: 1.0).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _earned == null ? _pass(state, clipped) : _success(state),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pass(RewardsState state, List<Deal> clipped) {
    return Column(
      key: const ValueKey('pass'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Brand.white,
            borderRadius: BorderRadius.circular(Radii.xl),
            boxShadow: [
              BoxShadow(color: Brand.ink.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
                child: Row(
                  children: [
                    const CMLogo(height: 30, plate: false),
                    const Spacer(),
                    TierChip(tier: state.tier, onDark: false),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Theme(
                  data: buildTheme(CMColors.light),
                  child: SegmentedTabs(
                    labels: const ['QR code', 'Barcode'],
                    index: _barcode ? 1 : 0,
                    onChanged: (i) => setState(() => _barcode = i == 1),
                  ),
                ),
              ),
              TickBuilder(
                builder: (context) {
                  final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                  final window = seconds ~/ _rotation;
                  final left = _rotation - seconds % _rotation;
                  final seed = int.parse(state.phoneDigits.padLeft(10, '0')) ^ window;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _scanning
                              ? const SizedBox(
                                  key: ValueKey('scanning'),
                                  height: 230,
                                  child: Center(child: MarketDots(color: Brand.green, size: 10)),
                                )
                              : _barcode
                              ? SizedBox(
                                  key: ValueKey('bar-$window'),
                                  height: 230,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 120,
                                        width: double.infinity,
                                        child: CustomPaint(painter: BarcodePainter('${state.phoneDigits}$window')),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(
                                  key: ValueKey('qr-$window'),
                                  width: 230,
                                  height: 230,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(painter: QrPainter(seed: seed)),
                                      ),
                                      Container(
                                        width: 54,
                                        height: 54,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Brand.white,
                                          borderRadius: BorderRadius.circular(Radii.sm),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Brand.burgundy,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'CM',
                                            style: TextStyle(
                                              fontFamily: AppText.slab,
                                              color: Brand.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Text(
                        state.memberId,
                        style: const TextStyle(
                          color: Brand.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              value: left / _rotation,
                              strokeWidth: 2.2,
                              color: Brand.green,
                              backgroundColor: Brand.ink.withValues(alpha: 0.08),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Secure code refreshes in 0:${left.toString().padLeft(2, '0')}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Brand.ink.withValues(alpha: 0.55),
                                fontSize: 12.5,
                                fontFeatures: AppText.tabular,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              TicketDivider(notchColor: Brand.burgundy.withValues(alpha: 0.95)),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                child: Row(
                  children: [
                    Expanded(child: _stat('Available', '${formatNumber(state.points)} pts')),
                    Container(width: 1, height: 32, color: Brand.ink.withValues(alpha: 0.08)),
                    Expanded(child: _stat('Earning', '${state.tier.multiplier}× points')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (clipped.isNotEmpty)
          _onDarkRow(
            CMGlyph.clip,
            '${clipped.length} clipped ${clipped.length == 1 ? 'offer' : 'offers'} will apply',
            clipped.map((d) => d.title).join(', '),
          )
        else
          _onDarkRow(CMGlyph.sun, 'Turn up your brightness', 'It helps the scanner read your code faster.'),
        const SizedBox(height: 18),
        PrimaryButton(
          label: Theme.of(context).platform == TargetPlatform.iOS ? 'Add to Apple Wallet' : 'Add to Google Wallet',
          icon: CMGlyph.wallet,
          tone: ButtonTone.dark,
          height: 54,
          onPressed: () => showToast(context, 'Pass added to your wallet', icon: CMGlyph.wallet),
        ),
        const SizedBox(height: 6),
        if (AppConfig.demo)
          TextButton.icon(
            onPressed: _scanning ? null : _simulateScan,
            style: TextButton.styleFrom(foregroundColor: Brand.white.withValues(alpha: 0.85)),
            icon: const CMIcon(CMGlyph.register, size: 18),
            label: const Text('Demo: simulate a scan at checkout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Brand.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            fontFeatures: AppText.tabular,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Brand.ink.withValues(alpha: 0.5), fontSize: 12)),
      ],
    );
  }

  Widget _onDarkRow(CMGlyph icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Brand.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CMIcon(icon, color: Brand.greenBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Brand.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(RewardsState state) {
    final (earned, store) = _earned!;
    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: 40),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Brand.green,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Brand.green.withValues(alpha: 0.5), blurRadius: 40)],
            ),
            child: const CMIcon(CMGlyph.check, color: Brand.white, size: 56),
          ),
        ),
        const SizedBox(height: 28),
        const Eyebrow('Scanned at checkout', color: Brand.greenBright),
        const SizedBox(height: 10),
        AnimatedCount(
          value: earned,
          from: 0,
          builder: (context, value) => Text('+$value', style: AppText.hero.copyWith(color: Brand.white, fontSize: 72)),
        ),
        const Text(
          'points earned',
          style: TextStyle(color: Brand.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text('at ${store.name} · ${store.street}', style: TextStyle(color: Brand.white.withValues(alpha: 0.7))),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Brand.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New balance: ${formatNumber(state.points)} points',
                  style: const TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        PrimaryButton(label: 'Done', tone: ButtonTone.light, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
