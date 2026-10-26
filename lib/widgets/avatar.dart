import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/rewards_state.dart';
import 'common.dart';
import 'motion.dart';
import 'cm_icons.dart';

/// Characters a member can pick as their profile picture.
const avatarCharacters = ['🦊', '🐻', '🐼', '🦁', '🐯', '🐨', '🐸', '🦉', '🐧', '🐶', '🐱', '🐰'];

/// Backgrounds for the avatar, all from the brand palette.
const avatarColors = [
  Brand.burgundy,
  Brand.green,
  Brand.champagneDeep,
  Brand.ink,
  Brand.burgundyBright,
  Brand.greenDeep,
];

/// The member's picture: their character, or initials, in a ring tinted by tier.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    final state = RewardsScope.of(context);
    return AvatarFace(
      emoji: state.avatar,
      initials: state.initials,
      color: avatarColors[state.avatarColor.clamp(0, avatarColors.length - 1)],
      ring: state.tier.color,
      size: size,
    );
  }
}

class AvatarFace extends StatelessWidget {
  const AvatarFace({
    super.key,
    required this.emoji,
    required this.initials,
    required this.color,
    required this.ring,
    this.size = 46,
  });

  final String emoji;
  final String initials;
  final Color color;
  final Color ring;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [ring, Brand.green, ring]),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: context.cm.background, width: size * 0.04),
        ),
        child: emoji.isEmpty
            ? Text(
                initials,
                style: TextStyle(color: Brand.white, fontWeight: FontWeight.w800, fontSize: size * 0.34),
              )
            : Text(emoji, style: TextStyle(fontSize: size * 0.48)),
      ),
    );
  }
}

Future<void> showAvatarPicker(BuildContext context) => showAppSheet<void>(context, (context) => const _AvatarPicker());

class _AvatarPicker extends StatefulWidget {
  const _AvatarPicker();

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  late final RewardsState _state = RewardsScope.read(context);
  late String _emoji = _state.avatar;
  late int _color = _state.avatarColor;

  @override
  Widget build(BuildContext context) {
    final c = context.cm;
    return Column(
      children: [
        AvatarFace(
          emoji: _emoji,
          initials: _state.initials,
          color: avatarColors[_color],
          ring: _state.tier.color,
          size: 104,
        ),
        const SizedBox(height: 14),
        const Text('Pick your character', style: AppText.headline),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _choice(
              c,
              '',
              selected: _emoji.isEmpty,
              child: Text(_state.initials, style: AppText.title),
            ),
            for (final e in avatarCharacters)
              _choice(
                c,
                e,
                selected: _emoji == e,
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < avatarColors.length; i++)
              Pressable(
                semanticLabel: 'Color ${i + 1}',
                onTap: () => setState(() => _color = i),
                child: AnimatedContainer(
                  duration: Motion.medium,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: avatarColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: _color == i ? c.ink : c.line, width: _color == i ? 2.5 : 1),
                  ),
                  child: _color == i ? const CMIcon(CMGlyph.check, color: Brand.white, size: 18) : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Save',
          onPressed: () {
            _state.setAvatar(_emoji, _color);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _choice(CMColors c, String value, {required bool selected, required Widget child}) {
    return Pressable(
      semanticLabel: value.isEmpty ? 'Initials' : 'Character $value',
      onTap: () => setState(() => _emoji = value),
      child: AnimatedContainer(
        duration: Motion.medium,
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? c.primaryInk : c.line, width: selected ? 2 : 1),
        ),
        child: child,
      ),
    );
  }
}
