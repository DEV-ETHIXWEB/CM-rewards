import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../data/auth_api.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/rewards_state.dart';
import '../widgets/avatar.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'activity.dart';
import 'auth.dart';
import 'home.dart';
import 'rewards.dart';
import 'sheets.dart';
import '../widgets/cm_icons.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, {bool delete = false}) async {
    final c = context.cm;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(delete ? 'Delete your account?' : 'Sign out?', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          delete
              ? 'This permanently removes your points, rewards and history. This can’t be undone.'
              : 'You can sign back in anytime with your phone number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: c.muted),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: delete ? c.danger : c.primary),
            child: Text(delete ? 'Delete' : 'Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final state = RewardsScope.read(context);
    if (delete) {
      try {
        await state.deleteAccount();
      } on AuthException catch (e) {
        if (!context.mounted) return;
        // The account stays until the server confirms it's gone.
        showToast(context, authFailureMessage(e, deleting: true), icon: CMGlyph.info);
        return;
      }
    } else {
      fireAndForget(state.signOut());
    }
    if (!context.mounted) return;
    fireAndForget(Navigator.of(context).pushAndRemoveUntil(fadeRoute<void>(const LoginScreen()), (route) => false));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final since = state.memberSince;

    return Scaffold(
      appBar: ContentAppBar(AppBar(title: const Text('Account'))),
      body: ContentWidth(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
          children: [
            reveal(
              0,
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: c.isDark ? Border.all(color: c.line) : null,
                  boxShadow: c.elevation(),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 168,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            bottom: 48,
                            child: BrandPhoto(storeExteriorPhoto, alignment: Alignment(0, 0.2)),
                          ),
                          const Positioned.fill(
                            bottom: 48,
                            child: Scrim(from: 0, opacity: 0.55, color: Brand.burgundyDeep),
                          ),
                          Positioned(
                            left: 18,
                            bottom: 0,
                            child: Pressable(
                              semanticLabel: 'Change profile picture',
                              onTap: () => showAvatarPicker(context),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Avatar(size: 92),
                                  Positioned(
                                    right: 0,
                                    bottom: 2,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: c.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: c.line),
                                      ),
                                      child: CMIcon(CMGlyph.pencil, size: 15, color: c.primaryInk),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(right: 16, bottom: 60, child: TierChip(tier: state.tier)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(state.name.isEmpty ? 'CM Rewards member' : state.name, style: AppText.headline),
                                const SizedBox(height: 2),
                                Text(
                                  '+1 ${state.phone} · Member since ${months[since.month - 1]} ${since.year}',
                                  style: TextStyle(color: c.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Stat(value: formatNumber(state.points), label: 'Points'),
                          ),
                          Expanded(
                            child: _Stat(value: '${state.visits}', label: 'Visits'),
                          ),
                          Expanded(
                            child: _Stat(value: formatMoney(state.savedCents), label: 'Saved'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            reveal(
              1,
              ListGroup(
                title: 'Rewards',
                children: [
                  ListRow(
                    icon: CMGlyph.receipt,
                    title: 'Points activity',
                    subtitle: '${state.redeemedCount} rewards redeemed',
                    onTap: () => push<void>(context, const ActivityScreen()),
                  ),
                  ListRow(
                    icon: CMGlyph.medal,
                    title: 'Tiers & perks',
                    subtitle: '${state.tier.label} · ${state.tier.multiplier}× points',
                    onTap: () => showAppSheet<void>(context, (context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tiers & perks', style: AppText.headline),
                          const SizedBox(height: 14),
                          TierLadder(lifetimePoints: RewardsScope.of(context).lifetimePoints),
                        ],
                      );
                    }),
                  ),
                  ListRow(
                    icon: CMGlyph.people,
                    title: 'Refer a friend',
                    subtitle: 'You both get ${RewardsState.referralBonus} points',
                    iconColor: c.positiveInk,
                    iconBackground: c.positiveSoft,
                    onTap: () => showReferralSheet(context),
                  ),
                  ListRow(
                    icon: CMGlyph.handHeart,
                    title: 'Gift points',
                    subtitle: 'Send points to friends and family',
                    onTap: () => showGiftSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            reveal(
              2,
              ListGroup(
                title: 'Profile',
                children: [
                  ListRow(
                    icon: CMGlyph.idCard,
                    title: 'Personal info',
                    subtitle: state.name.isEmpty
                        ? 'Add your name'
                        : [state.name, if (state.email.isNotEmpty) state.email].join(' · '),
                    onTap: () => showEditProfileSheet(context),
                  ),
                  ListRow(
                    icon: CMGlyph.home,
                    title: 'Home store',
                    subtitle: '${state.home.name} · ${state.home.street}',
                    onTap: () => showHomeStorePicker(context),
                  ),
                  ListRow(
                    icon: CMGlyph.card,
                    title: 'Payment methods',
                    subtitle: state.payment.label,
                    onTap: () => showPaymentsSheet(context),
                  ),
                  ListRow(
                    icon: CMGlyph.heart,
                    title: 'Your favorites',
                    subtitle: state.interests.isEmpty ? 'Tell us what you like' : '${state.interests.length} picked',
                    onTap: () => showInterestsSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            reveal(3, Padding(padding: const EdgeInsets.fromLTRB(6, 0, 6, 10), child: const Eyebrow('Appearance'))),
            reveal(3, const _AppearancePicker()),
            const SizedBox(height: 22),
            reveal(
              4,
              ListGroup(
                title: 'Preferences',
                children: [
                  ListRow(
                    icon: CMGlyph.bell,
                    title: 'Notifications',
                    subtitle: _notifySummary(state),
                    onTap: () => showNotificationPrefsSheet(context),
                  ),
                  ListRow(
                    icon: CMGlyph.sparkle,
                    title: 'Personalized offers',
                    subtitle: 'Based on what you buy',
                    trailing: Switch.adaptive(value: state.personalizedOffers, onChanged: state.setPersonalizedOffers),
                  ),
                  ListRow(
                    icon: CMGlyph.sound,
                    title: 'Tap sounds',
                    subtitle: 'A soft click when you tap',
                    trailing: Switch.adaptive(
                      key: const ValueKey('sounds-switch'),
                      value: state.soundsEnabled,
                      onChanged: state.setSounds,
                    ),
                  ),
                  ListRow(
                    icon: CMGlyph.vibrate,
                    title: 'Haptic feedback',
                    subtitle: 'Gentle vibrations on taps',
                    trailing: Switch.adaptive(
                      key: const ValueKey('haptics-switch'),
                      value: state.hapticsEnabled,
                      onChanged: state.setHaptics,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            reveal(
              5,
              ListGroup(
                title: 'Support',
                children: [
                  ListRow(icon: CMGlyph.help, title: 'Help & FAQ', onTap: () => showHelpSheet(context)),
                  ListRow(
                    icon: CMGlyph.chat,
                    title: 'Contact us',
                    subtitle: 'We usually reply within a day',
                    onTap: () => launchExternal(
                      context,
                      Uri(scheme: 'mailto', path: 'rewards@centermarkets.com', query: 'subject=CM Rewards help'),
                      'No email app found on this device.',
                    ),
                  ),
                  ListRow(icon: CMGlyph.info, title: 'About Center Market', onTap: () => showAboutSheet(context)),
                  ListRow(
                    icon: CMGlyph.code,
                    title: 'Open-source licenses',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'CM Rewards',
                      applicationIcon: const Padding(padding: EdgeInsets.all(12), child: CMLogo(height: 48)),
                    ),
                  ),
                  // Only real, published pages; never a stand-in.
                  if (AppConfig.privacyPolicyUrl case final url?)
                    ListRow(
                      icon: CMGlyph.shield,
                      title: 'Privacy policy',
                      onTap: () => launchExternal(context, url, 'Could not open the privacy policy.'),
                    ),
                  if (AppConfig.termsUrl case final url?)
                    ListRow(
                      icon: CMGlyph.receipt,
                      title: 'Terms of use',
                      onTap: () => launchExternal(context, url, 'Could not open the terms of use.'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.ink,
                  side: BorderSide(color: c.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                ),
                icon: const CMIcon(CMGlyph.logout),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _signOut(context, delete: true),
                style: TextButton.styleFrom(foregroundColor: c.danger),
                child: const Text('Delete account', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: _VersionLabel()),
          ],
        ),
      ),
    );
  }

  String _notifySummary(RewardsState state) {
    final on = [if (state.notifyDeals) 'Deals', if (state.notifyRewards) 'Rewards', if (state.notifyOrders) 'Orders'];
    return on.isEmpty ? 'Off' : on.join(', ');
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(Radii.md)),
      child: Column(
        children: [
          FittedBox(
            child: Text(value, style: AppText.headline.copyWith(fontSize: 20, fontFeatures: AppText.tabular)),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }
}

// ─── Account sheets ───────────────────────────────────────────────────────────

Future<void> showEditProfileSheet(BuildContext context) =>
    showAppSheet<void>(context, (context) => const _EditProfileForm());

InputDecoration _fieldDecoration(CMColors c, String hint, CMGlyph icon, {String? error}) => InputDecoration(
  hintText: hint,
  errorText: error,
  prefixIcon: CMIcon(icon, color: c.muted),
  filled: true,
  fillColor: c.surface,
  counterText: '',
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
);

/// Owns its text controllers, so they live exactly as long as the sheet,
/// including its closing animation.
class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm();

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late final RewardsState _state = RewardsScope.read(context);
  late final _name = TextEditingController(text: _state.name);
  late final _email = TextEditingController(text: _state.email);
  late DateTime? _birthday = _state.birthday;
  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 110),
      // Members must be at least 13.
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  void _save() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Please enter your name' : null;
      _emailError = email.isNotEmpty && !isValidEmail(email) ? 'That email doesn’t look right' : null;
    });
    if (_nameError != null || _emailError != null) return;
    _state
      ..setName(name)
      ..setEmail(email)
      ..setBirthday(_birthday);
    Navigator.of(context).pop();
    showToast(context, 'Profile updated');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final birthday = _birthday;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal info', style: AppText.headline),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            maxLength: maxNameLength,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(c, 'Name', CMGlyph.person, error: _nameError),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: _fieldDecoration(c, 'Email (for receipts)', CMGlyph.mail, error: _emailError),
          ),
          const SizedBox(height: 10),
          Pressable(
            semanticLabel: 'Birthday',
            onTap: _pickBirthday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  CMIcon(CMGlyph.cake, color: c.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      birthday == null ? 'Birthday (we’ll send a treat)' : formatDate(birthday),
                      style: TextStyle(color: birthday == null ? c.hint : c.ink, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(Radii.md)),
            child: Row(
              children: [
                CMIcon(CMGlyph.device, color: c.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('+1 ${_state.phone}', style: TextStyle(color: c.muted, fontSize: 16)),
                ),
                CMIcon(CMGlyph.lock, size: 18, color: c.hint),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save', onPressed: _save),
        ],
      ),
    );
  }
}

Future<void> showHomeStorePicker(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Home store', style: AppText.headline),
        const SizedBox(height: 4),
        Text('Its hours, fuel and pickup show up first.', style: TextStyle(color: c.muted)),
        const SizedBox(height: 14),
        ListGroup(
          children: [
            for (final s in stores)
              ListRow(
                icon: CMGlyph.storeFill,
                title: s.name,
                subtitle: '${s.street} · ${s.distanceLabel}',
                onTap: () {
                  state.setHomeStore(s.number);
                  Navigator.of(context).pop();
                },
                trailing: CMIcon(
                  state.homeStore == s.number ? CMGlyph.radioOn : CMGlyph.radioOff,
                  color: state.homeStore == s.number ? c.primaryInk : c.hint,
                ),
              ),
          ],
        ),
      ],
    );
  });
}

Future<void> showPaymentsSheet(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment methods', style: AppText.headline),
        const SizedBox(height: 4),
        Text('Used for Order Ahead. Tap to make one your default.', style: TextStyle(color: c.muted)),
        const SizedBox(height: 14),
        ListGroup(
          children: [
            for (final m in state.availablePaymentMethods)
              ListRow(
                icon: m.icon,
                title: m.label,
                subtitle: m.detail,
                onTap: () => state.setDefaultPayment(m.id),
                trailing: state.payment.id == m.id
                    ? const StatusPill(label: 'Default', positive: true, dot: false)
                    : null,
              ),
          ],
        ),
      ],
    );
  });
}

Future<void> showInterestsSheet(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your favorites', style: AppText.headline),
        const SizedBox(height: 4),
        Text('We use these to pick your offers.', style: TextStyle(color: c.muted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (id, emoji, label) in interestOptions)
              Pressable(
                semanticLabel: label,
                onTap: () => state.toggleInterest(id),
                child: AnimatedContainer(
                  duration: Motion.medium,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: state.interests.contains(id) ? c.primarySoft : c.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: state.interests.contains(id) ? c.primaryInk : c.line,
                      width: state.interests.contains(id) ? 1.6 : 1,
                    ),
                  ),
                  child: Text('$emoji  $label', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ],
    );
  });
}

Future<void> showNotificationPrefsSheet(BuildContext context) {
  return showAppSheet<void>(context, (context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    final rows = [
      (NoticeKind.deals, 'Deals & new stores', 'Weekly offers and grand openings', state.notifyDeals),
      (NoticeKind.rewards, 'Rewards & points', 'When you earn, unlock or are close', state.notifyRewards),
      (NoticeKind.orders, 'Order updates', 'When your Order Ahead is ready', state.notifyOrders),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notifications', style: AppText.headline),
        const SizedBox(height: 4),
        Text('Choose what we ping you about. We keep it light.', style: TextStyle(color: c.muted)),
        const SizedBox(height: 14),
        ListGroup(
          children: [
            for (final (kind, title, subtitle, value) in rows)
              ListRow(
                icon: kind.icon,
                title: title,
                subtitle: subtitle,
                trailing: Switch.adaptive(value: value, onChanged: (v) => state.setNotify(kind, v)),
              ),
          ],
        ),
      ],
    );
  });
}

/// The installed version and build, read from the platform so it never drifts
/// from pubspec.yaml.
class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  static final _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info == null ? '' : ' ${info.version} (${info.buildNumber})';
        return Text('CM Rewards$version · Made in Oregon', style: TextStyle(fontSize: 12, color: context.cm.hint));
      },
    );
  }
}

/// Light, dark or system, each shown as a tiny preview of the app.
class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker();

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    final state = RewardsScope.of(context);
    const options = [(ThemeMode.system, 'System'), (ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark')];
    return Row(
      children: [
        for (final (mode, label) in options) ...[
          if (mode != ThemeMode.system) const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              semanticLabel: '$label appearance',
              onTap: () => state.setThemeMode(mode),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: Motion.medium,
                    height: 92,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(
                        color: state.themeMode == mode ? c.primaryInk : c.line,
                        width: state.themeMode == mode ? 2.2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: switch (mode) {
                        ThemeMode.light => const _MiniApp(colors: CMColors.light),
                        ThemeMode.dark => const _MiniApp(colors: CMColors.dark),
                        ThemeMode.system => const Row(
                          children: [
                            Expanded(child: _MiniApp(colors: CMColors.light)),
                            Expanded(child: _MiniApp(colors: CMColors.dark)),
                          ],
                        ),
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CMIcon(
                          state.themeMode == mode ? CMGlyph.radioOn : CMGlyph.radioOff,
                          size: 16,
                          color: state.themeMode == mode ? c.primaryInk : c.hint,
                        ),
                        const SizedBox(width: 6),
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
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

/// A thumbnail of the home screen in the given colors.
class _MiniApp extends StatelessWidget {
  const _MiniApp({required this.colors});

  final CMColors colors;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, Color color) => Container(
      width: width,
      height: 6,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
    return Container(
      color: colors.background,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(30, colors.ink.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Brand.burgundyBright, Brand.burgundyDeep]),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: bar(double.infinity, colors.surface)),
              const SizedBox(width: 4),
              Expanded(child: bar(double.infinity, colors.positive)),
            ],
          ),
        ],
      ),
    );
  }
}
