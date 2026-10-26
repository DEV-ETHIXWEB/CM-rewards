import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'shell.dart';
import '../widgets/cm_icons.dart';

class _UsPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

void enterApp(BuildContext context, {bool personalize = false}) {
  fireAndForget(
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute<void>(personalize ? const PersonalizeScreen() : const MainShell()),
      (route) => false,
    ),
  );
}

// ─── Login ────────────────────────────────────────────────────────────────────

const _pitches = [
  ('CM Rewards', 'Earn on every visit.', 'Points on coffee, hot food, snacks and fuel at every Center Market.'),
  ('Order Ahead', 'Skip the line.', 'Order chicken, pizza and coffee from your phone. It’s ready when you are.'),
  ('Fuel Savings', 'Save at the pump.', 'Members save up to 10¢ a gallon, every fill, at participating stores.'),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  int _pitch = 0;
  Timer? _rotate;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _isValid => isValidUsPhone(_digits);

  /// Explains a complete-but-impossible number, like one starting with 0 or 1.
  String? get _phoneProblem => _digits.length == 10 && !_isValid ? 'Enter a valid US mobile number' : null;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
    _rotate = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_focus.hasFocus) setState(() => _pitch = (_pitch + 1) % _pitches.length);
    });
  }

  @override
  void dispose() {
    _rotate?.cancel();
    _phone.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sending = false);
    fireAndForget(push<void>(context, OtpScreen(phoneDigits: _digits)));
  }

  void _demoMode() {
    RewardsScope.read(context)
      ..haptic()
      ..signIn('5551234567', skipProfile: true);
    enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.5).clamp(300.0, 470.0);
    final (eyebrow, headline, body) = _pitches[_pitch];

    final hero = Stack(
      fit: StackFit.expand,
      children: [
        const BrandVideo(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.3, 1],
              colors: [
                Brand.ink.withValues(alpha: 0.55),
                Brand.ink.withValues(alpha: 0.05),
                Brand.burgundyDeep.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        Positioned(
          left: 22,
          top: MediaQuery.paddingOf(context).top + 12,
          // Flies in from the splash screen.
          child: const Hero(tag: 'cm-logo', child: CMLogo(height: 40, plate: true)),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Motion.standard,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_pitch),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow, color: Brand.greenBright),
                const SizedBox(height: 8),
                Text(headline, style: AppText.hero.copyWith(color: Brand.white)),
                const SizedBox(height: 8),
                Text(body, style: TextStyle(color: Brand.white.withValues(alpha: 0.82), fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          bottom: 26,
          child: Row(
            children: [
              for (var i = 0; i < _pitches.length; i++)
                AnimatedContainer(
                  duration: Motion.medium,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _pitch ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _pitch ? Brand.greenBright : Brand.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final form = Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reveal(1, const Text('Sign in or join CM Rewards', style: AppText.title)),
          const SizedBox(height: 4),
          reveal(1, Text("It's free. We'll text you a code.", style: TextStyle(color: c.muted, fontSize: 14.5))),
          const SizedBox(height: 18),
          reveal(2, _phoneField(c)),
          if (_phoneProblem case final problem?) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                problem,
                style: TextStyle(color: c.danger, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 14),
          reveal(3, PrimaryButton(label: 'Continue', loading: _sending, onPressed: _isValid ? _sendCode : null)),
          if (AppConfig.demo) ...[
            const SizedBox(height: 18),
            reveal(
              4,
              Row(
                children: [
                  Expanded(child: Divider(color: c.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: c.muted, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: c.line)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            reveal(
              4,
              Column(children: [_socialButton(c, 'Apple'), const SizedBox(height: 10), _socialButton(c, 'Google')]),
            ),
            const SizedBox(height: 10),
            reveal(
              5,
              Center(
                child: TextButton.icon(
                  onPressed: _demoMode,
                  style: TextButton.styleFrom(foregroundColor: c.positiveInk),
                  icon: const CMIcon(CMGlyph.play, size: 20),
                  label: const Text('Explore in Demo Mode', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Center(
            child: Text(
              'By continuing you agree to the CM Rewards Terms and Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.hint),
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The status bar sits over the video on phones, over the form when side by side.
      value: context.isExpandedWidth && !c.isDark ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: context.isExpandedWidth
            // Wide screens: the film fills the left, the form sits on the right.
            ? Row(
                children: [
                  Expanded(child: hero),
                  SizedBox(
                    width: 500,
                    child: Center(
                      child: SingleChildScrollView(child: SafeArea(child: form)),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: heroHeight, child: hero),
                    ContentWidth(maxWidth: 560, child: form),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _phoneField(CMColors c) {
    return AnimatedContainer(
      duration: Motion.medium,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: _focus.hasFocus ? c.primaryInk : c.line, width: _focus.hasFocus ? 1.6 : 1),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('🇺🇸  +1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Container(width: 1, height: 26, color: c.line),
          Expanded(
            child: TextField(
              controller: _phone,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [_UsPhoneFormatter()],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              onSubmitted: (_) => _isValid ? _sendCode() : null,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                hintText: '(555) 123-4567',
                hintStyle: TextStyle(color: c.hint),
              ),
            ),
          ),
          AnimatedScale(
            scale: _isValid ? 1 : 0,
            duration: Motion.medium,
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CMIcon(CMGlyph.checkCircle, color: c.positive),
            ),
          ),
        ],
      ),
    );
  }

  // Demo-only stand-ins. A real build uses each provider's official sign-in
  // button, since their logos are trademarks we don't redraw.
  Widget _socialButton(CMColors c, String provider) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          RewardsScope.read(context)
            ..haptic()
            ..signIn('5551234567');
          enterApp(context, personalize: true);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
          textStyle: const TextStyle(fontFamily: AppText.sans, fontWeight: FontWeight.w700),
        ),
        child: Text('Continue with $provider'),
      ),
    );
  }
}

// ─── OTP verification (simulated) ─────────────────────────────────────────────

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneDigits});

  final String phoneDigits;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;

  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _verifying = false;
  bool _verified = false;
  int _resendIn = 30;
  Timer? _timer;

  // Brute-force protection: a few tries, then a cool-down. The server must
  // enforce the same limits; this keeps honest users informed.
  static const _maxAttempts = 5;
  static const _maxResends = 3;
  static const _lockout = Duration(seconds: 60);
  int _attempts = 0;
  int _resends = 0;
  DateTime? _lockedUntil;
  String? _error;

  bool get _locked => _lockedUntil?.isAfter(DateTime.now()) ?? false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _resendIn = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendIn--;
        if (_resendIn <= 0) timer.cancel();
      });
    });
  }

  void _resend() {
    if (_resends >= _maxResends) {
      setState(() => _error = 'Too many codes requested. Please try again later.');
      return;
    }
    _resends++;
    setState(() {
      _startResendTimer();
      _error = null;
      _code.clear();
    });
    showToast(context, 'New code sent to +1 ${formatPhone(widget.phoneDigits)}', icon: CMGlyph.chat);
  }

  /// Without a backend, any code but 000000 passes, so the error path can be tried.
  bool _codeAccepted(String code) => code != '000000';

  Future<void> _verify() async {
    if (_code.text.length != _length || _verifying || _locked) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (!_codeAccepted(_code.text)) {
      _attempts++;
      final left = _maxAttempts - _attempts;
      setState(() {
        _verifying = false;
        _code.clear();
        if (left <= 0) {
          _attempts = 0;
          _lockedUntil = DateTime.now().add(_lockout);
          _error = 'Too many tries. Please wait a minute and try again.';
        } else {
          _error = 'That code didn’t work. $left ${left == 1 ? 'try' : 'tries'} left.';
        }
      });
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _verified = true);
    RewardsScope.read(context).haptic(strong: true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    RewardsScope.read(context).signIn(widget.phoneDigits);
    enterApp(context, personalize: true);
  }

  Widget _codeBoxes(CMColors c) {
    final code = _code.text;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          Row(
            children: List.generate(_length, (i) {
              final filled = i < code.length;
              final active = i == code.length && _focus.hasFocus;
              // Every box gets an equal slot; the gap between the two groups
              // of three sits outside the slots so all six stay the same size.
              final box = Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AspectRatio(
                    aspectRatio: 0.8,
                    child: AnimatedContainer(
                      duration: Motion.medium,
                      curve: Motion.standard,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _verified ? c.positiveSoft : c.surface,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(
                          color: _verified
                              ? c.positive
                              : active
                              ? c.primaryInk
                              : filled
                              ? c.ink.withValues(alpha: 0.3)
                              : c.line,
                          width: active ? 2 : 1.2,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Text(
                          filled ? code[i] : '',
                          key: ValueKey('$i-${filled ? code[i] : ''}'),
                          style: AppText.headline.copyWith(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              return i == _length ~/ 2 ? [const SizedBox(width: 10), box] : [box];
            }).expand((w) => w).toList(),
          ),
          // Invisible field that captures the keyboard input for the boxes.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _code,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_length)],
                showCursor: false,
                enableInteractiveSelection: false,
                onChanged: (value) {
                  RewardsScope.read(context).haptic();
                  setState(() {});
                  if (value.length == _length) unawaited(_verify());
                },
                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Scaffold(
      appBar: AppBar(),
      body: ContentWidth(
        maxWidth: 520,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                reveal(
                  0,
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: IconTile(
                      key: ValueKey(_verified),
                      icon: _verified ? CMGlyph.check : CMGlyph.chat,
                      size: 64,
                      color: _verified ? Brand.white : c.primaryInk,
                      background: _verified ? c.positive : c.primarySoft,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                reveal(1, const Text('Enter your code', style: AppText.display)),
                const SizedBox(height: 8),
                reveal(
                  2,
                  Text.rich(
                    TextSpan(
                      text: 'We texted a 6-digit code to ',
                      children: [
                        TextSpan(
                          text: '+1 ${formatPhone(widget.phoneDigits)}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 15, color: c.muted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 30),
                reveal(3, _codeBoxes(c)),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: TextStyle(color: c.danger, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 16),
                if (AppConfig.demo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: c.positiveSoft, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CMIcon(CMGlyph.info, size: 16, color: c.positiveInk),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Demo: any 6 digits work (000000 shows an error)',
                            style: TextStyle(fontSize: 13, color: c.positiveInk, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
                PrimaryButton(
                  label: _verified ? 'Verified' : 'Verify & Continue',
                  icon: _verified ? CMGlyph.check : null,
                  tone: _verified ? ButtonTone.positive : ButtonTone.primary,
                  loading: _verifying && !_verified,
                  onPressed: _code.text.length == _length && !_locked ? _verify : null,
                ),
                const SizedBox(height: 14),
                Center(
                  child: _resendIn > 0
                      ? Text(
                          'Resend code in 0:${_resendIn.toString().padLeft(2, '0')}',
                          style: TextStyle(color: c.muted, fontFeatures: AppText.tabular),
                        )
                      : TextButton(
                          onPressed: _resend,
                          style: TextButton.styleFrom(foregroundColor: c.primaryInk),
                          child: const Text('Resend code', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Personalize ──────────────────────────────────────────────────────────────

class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  final _name = TextEditingController();
  final Set<String> _interests = {};
  int _store = stores.first.number;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish({bool skipped = false}) {
    final state = RewardsScope.read(context)..haptic(strong: true);
    state.completeProfile(
      name: skipped ? '' : _name.text,
      interests: skipped ? state.interests : _interests,
      homeStore: _store,
    );
    enterApp(context);
    showToast(context, 'Welcome to CM Rewards, ${state.firstName}!', icon: CMGlyph.sparkle);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _finish(skipped: true),
            style: TextButton.styleFrom(foregroundColor: c.muted),
            child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ContentWidth(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 140),
          children: [
            reveal(0, Eyebrow('Step 2 of 2', color: c.positiveInk)),
            const SizedBox(height: 8),
            reveal(0, const Text('Make it yours', style: AppText.display)),
            const SizedBox(height: 6),
            reveal(
              1,
              Text(
                'Tell us a little about you and we’ll tailor offers to what you actually buy.',
                style: TextStyle(color: c.muted, fontSize: 15, height: 1.45),
              ),
            ),
            const SizedBox(height: 26),
            reveal(2, const Text('What should we call you?', style: TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            reveal(
              2,
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'First name',
                  filled: true,
                  fillColor: c.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide(color: c.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide(color: c.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide(color: c.primaryInk, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            reveal(3, const Text('What do you usually grab?', style: TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            reveal(
              3,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (id, emoji, label) in interestOptions)
                    _InterestChip(
                      emoji: emoji,
                      label: label,
                      selected: _interests.contains(id),
                      onTap: () => setState(() => _interests.contains(id) ? _interests.remove(id) : _interests.add(id)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            reveal(4, const Text('Your home store', style: TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(height: 4),
            reveal(
              4,
              Text('We’ll show its hours, fuel prices and pickup times first.', style: TextStyle(color: c.muted)),
            ),
            const SizedBox(height: 12),
            for (final store in stores.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: reveal(
                  5,
                  _StoreChoice(
                    store: store.number,
                    selected: _store == store.number,
                    onTap: () => setState(() => _store = store.number),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 516),
            child: PrimaryButton(label: 'Start earning', icon: CMGlyph.arrowRight, onPressed: _finish),
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.emoji, required this.label, required this.selected, required this.onTap});

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.medium,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? c.primaryInk : c.line, width: selected ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: selected ? c.primaryInk : c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreChoice extends StatelessWidget {
  const _StoreChoice({required this.store, required this.selected, required this.onTap});

  final int store;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final s = storeByNumber(store);
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: Motion.medium,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? c.primaryInk : c.line, width: selected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 56, height: 56, child: BrandPhoto(s.photo)),
            ),
            const SizedBox(width: 12),
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
            AnimatedSwitcher(
              duration: Motion.medium,
              child: CMIcon(
                selected ? CMGlyph.radioOn : CMGlyph.radioOff,
                key: ValueKey(selected),
                color: selected ? c.primaryInk : c.hint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
