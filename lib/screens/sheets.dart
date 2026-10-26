import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/cm_icons.dart';

Future<void> showAboutSheet(BuildContext context) {
  const values = [
    (CMGlyph.tools, 'Hard Work'),
    (CMGlyph.shield, 'Honesty'),
    (CMGlyph.heartFill, 'Putting People First'),
  ];
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const BrandPhoto(aerialPhoto, semanticLabel: 'Aerial view of a Center Market store'),
                const Scrim(from: 0.35, opacity: 0.7, color: Brand.burgundyDeep),
                const Positioned(left: 16, bottom: 16, child: CMLogo(height: 36, plate: true)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Eyebrow('Locally owned · Since 1999', color: c.positiveInk),
        const SizedBox(height: 6),
        const Text("Oregon's neighborhood market", style: AppText.headline),
        const SizedBox(height: 10),
        Text(
          'Center Market is a family-owned convenience store business proudly serving Oregon communities '
          'since 1999. What began as a single neighborhood store has grown into a network of trusted '
          'locations known for convenience, reliability and friendly service.',
          style: TextStyle(color: c.muted, height: 1.55),
        ),
        const SizedBox(height: 18),
        const Text('Our values', style: AppText.title),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, label) in values)
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
                    CMIcon(icon, size: 18, color: c.primaryInk),
                    const SizedBox(width: 6),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: const SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: BrandPhoto(ownersPhoto, semanticLabel: 'The Center Market family outside a store'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('The family behind the stores', style: TextStyle(color: c.muted, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: const SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: BrandPhoto(
                        anniversaryPhoto,
                        semanticLabel: 'Customers at a Center Market anniversary event',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Celebrating with neighbors', style: TextStyle(color: c.muted, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            label: 'Visit centermarkets.com',
            icon: CMGlyph.external,
            onPressed: () =>
                launchExternal(context, Uri.parse('https://www.centermarkets.com/'), 'Could not open the website.'),
          ),
        ),
      ],
    );
  });
}

Future<void> showHelpSheet(BuildContext context) {
  final faqs = [
    (
      'How do I earn points?',
      'Scan your member pass at checkout. You earn 10 points for every \$1 you spend in store, and more as you move up tiers.',
    ),
    (
      'How do I redeem a reward?',
      'Open Rewards, tap a reward you have enough points for, and show the code to the cashier.',
    ),
    (
      'How long is a reward code valid?',
      'Codes are valid for 15 minutes after you redeem. You can find active codes in your Wallet.',
    ),
    (
      'How does Order Ahead work?',
      'Pick a store, add items to your bag and pay in the app. We’ll let you know when it’s ready at the counter.',
    ),
    ('Do my points expire?', 'Points stay active as long as you make at least one purchase every 12 months.'),
    (
      'How do member tiers work?',
      'Your tier is based on lifetime points. Regular starts at ${formatNumber(Tier.regular.threshold)} and Insider at ${formatNumber(Tier.insider.threshold)}.',
    ),
    (
      'Can I save on fuel?',
      'Yes. Regular members save 5¢ and Insiders 10¢ per gallon, and you can redeem points for more.',
    ),
  ];
  return showAppSheet<void>(context, (context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Help & FAQ', style: AppText.headline),
        const SizedBox(height: 14),
        for (final (question, answer) in faqs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FaqTile(question: question, answer: answer),
          ),
      ],
    );
  });
}

Future<void> showHowToEarnSheet(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final steps = [
      (CMGlyph.scan, 'Scan at checkout', 'Earn ${state.tier.earnRate} points for every \$1.'),
      (CMGlyph.bagFill, 'Order ahead', 'Same points, no line. +${RewardsState.firstOrderBonus} on your first order.'),
      (CMGlyph.clip, 'Clip offers', 'Bonus points when you buy what you clipped.'),
      (
        CMGlyph.trophy,
        'Finish challenges',
        'Weekly goals worth up to ${challenges.map((c) => c.reward).reduce(max)} points each.',
      ),
      (CMGlyph.people, 'Invite friends', '${RewardsState.referralBonus} points for you and for them.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ways to earn', style: AppText.headline),
        const SizedBox(height: 16),
        for (final (i, (icon, title, body)) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                IconTile(
                  icon: icon,
                  color: i.isEven ? c.primaryInk : c.positiveInk,
                  background: i.isEven ? c.primarySoft : c.positiveSoft,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(body, style: TextStyle(color: c.muted, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  });
}

Future<void> showReferralSheet(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.positiveSoft, shape: BoxShape.circle),
          child: const Text('🎁', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 14),
        Text(
          'Give ${RewardsState.referralBonus}, get ${RewardsState.referralBonus}',
          style: AppText.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Invite friends to CM Rewards. After their first purchase, you both get ${RewardsState.referralBonus} bonus points.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5, color: c.muted),
        ),
        const SizedBox(height: 20),
        const ReferralCode(),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Share invite',
          icon: CMGlyph.share,
          tone: ButtonTone.dark,
          height: 52,
          onPressed: () => shareInvite(context),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text('3 friends joined so far', style: TextStyle(color: c.muted, fontSize: 13)),
            ),
            Text(
              '+${formatNumber(3 * RewardsState.referralBonus)} pts earned',
              style: TextStyle(color: c.positiveInk, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  });
}

class ReferralCode extends StatelessWidget {
  const ReferralCode({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final code = RewardsScope.of(context).referralCode;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: c.primaryInk.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Text(code, style: AppText.headline.copyWith(fontSize: 20, letterSpacing: 3)),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              RewardsScope.read(context).haptic();
              await Clipboard.setData(ClipboardData(text: code));
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Referral code copied')));
            },
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Brand.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            ),
            icon: const CMIcon(CMGlyph.copy, size: 18),
            label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

Future<void> showGiftSheet(BuildContext context) => showAppSheet<void>(context, (context) => const _GiftForm());

class _GiftForm extends StatefulWidget {
  const _GiftForm();

  @override
  State<_GiftForm> createState() => _GiftFormState();
}

class _GiftFormState extends State<_GiftForm> {
  static const _amounts = [250, 500, 1000];

  final _phone = TextEditingController();
  int _amount = _amounts.first;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? _problem(RewardsState state, String digits) {
    if (digits.length < 10) return null;
    if (!isValidUsPhone(digits)) return 'Enter a valid US phone number';
    if (digits == state.phoneDigits) return 'You can’t gift points to yourself';
    if (_amount > state.points) return 'You don’t have enough points';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final problem = _problem(state, digits);
    final valid = digits.length == 10 && problem == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gift points', style: AppText.headline),
          const SizedBox(height: 4),
          Text(
            'Send points to anyone with CM Rewards. You have ${formatNumber(state.points)}.',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: InputDecoration(
              hintText: 'Their 10-digit phone number',
              errorText: problem,
              prefixIcon: CMIcon(CMGlyph.person, color: c.muted),
              filled: true,
              fillColor: c.surface,
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
          const SizedBox(height: 14),
          Row(
            children: [
              for (final a in _amounts) ...[
                if (a != _amounts.first) const SizedBox(width: 8),
                Expanded(
                  child: Pressable(
                    semanticLabel: '${formatNumber(a)} points',
                    onTap: () => setState(() => _amount = a),
                    child: AnimatedContainer(
                      duration: Motion.medium,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _amount == a ? c.primarySoft : c.surface,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(color: _amount == a ? c.primaryInk : c.line, width: _amount == a ? 1.6 : 1),
                      ),
                      child: Text(
                        '${formatNumber(a)} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: a > state.points ? c.hint : (_amount == a ? c.primaryInk : c.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Send ${formatNumber(_amount)} points',
            icon: CMGlyph.send,
            onPressed: valid
                ? () {
                    if (!state.giftPoints(digits, _amount)) return;
                    state.haptic(strong: true);
                    Navigator.of(context).pop();
                    showToast(
                      context,
                      'Sent ${formatNumber(_amount)} points to +1 ${formatPhone(digits)}',
                      icon: CMGlyph.handHeart,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// Opens the system share sheet with the member's invite.
Future<void> shareInvite(BuildContext context) async {
  final state = RewardsScope.read(context);
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text:
          'Join me on CM Rewards at Center Market and we both get ${RewardsState.referralBonus} points. '
          'Use my code ${state.referralCode} when you sign up. https://www.centermarkets.com/',
      subject: 'Get ${RewardsState.referralBonus} points at Center Market',
      // iPad shows the share sheet as a popover anchored here.
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// A question that expands to show its answer, with a rotating chevron.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Semantics(
      expanded: _open,
      child: Pressable(
        scale: 0.99,
        onTap: () => setState(() => _open = !_open),
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.standard,
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: _open ? c.primaryInk.withValues(alpha: 0.35) : c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: Motion.medium,
                    curve: Motion.standard,
                    child: CMIcon(CMGlyph.chevronDown, size: 22, color: _open ? c.primaryInk : c.muted),
                  ),
                ],
              ),
              AnimatedSize(
                duration: Motion.medium,
                curve: Motion.standard,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, right: 8),
                        child: Text(widget.answer, style: TextStyle(color: c.muted, height: 1.5)),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
