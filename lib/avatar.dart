import 'package:flutter/material.dart';

const defaultAvatar = 'fox:0';

const avatarAnimals = <String, String>{
  'fox': '🦊',
  'cat': '🐱',
  'dog': '🐶',
  'panda': '🐼',
  'lion': '🦁',
  'tiger': '🐯',
  'frog': '🐸',
  'owl': '🦉',
  'octopus': '🐙',
  'penguin': '🐧',
  'koala': '🐨',
  'wolf': '🐺',
  'unicorn': '🦄',
  'dragon': '🐲',
  'robot': '🤖',
  'alien': '👽',
};

const avatarColors = <Color>[
  Color(0xFFFF7043),
  Color(0xFFFFB300),
  Color(0xFF9CCC65),
  Color(0xFF26A69A),
  Color(0xFF29B6F6),
  Color(0xFF5C6BC0),
  Color(0xFF977DFF),
  Color(0xFFEC407A),
  Color(0xFFE3EF26),
  Color(0xFF78909C),
];

({String animal, int color}) parseAvatar(String? s) {
  final parts = (s ?? defaultAvatar).split(':');
  var animal = parts.first;
  if (!avatarAnimals.containsKey(animal)) animal = 'fox';
  var color = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (color < 0 || color >= avatarColors.length) color = 0;
  return (animal: animal, color: color);
}

class AvatarWidget extends StatelessWidget {
  final String? avatar;
  final double radius;
  const AvatarWidget({super.key, this.avatar, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final a = parseAvatar(avatar);
    final base = avatarColors[a.color];
    final dark = HSLColor.fromColor(base)
        .withLightness(
            (HSLColor.fromColor(base).lightness * 0.6).clamp(0.0, 1.0))
        .toColor();
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, dark],
        ),
      ),
      child: Text(
        avatarAnimals[a.animal]!,
        style: TextStyle(fontSize: radius * 1.05),
      ),
    );
  }
}

/// Bottom sheet. Returns the chosen avatar string, or null if dismissed.
Future<String?> pickAvatar(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AvatarPicker(current: current),
  );
}

class _AvatarPicker extends StatefulWidget {
  final String current;
  const _AvatarPicker({required this.current});

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  late String _animal;
  late int _color;

  @override
  void initState() {
    super.initState();
    final a = parseAvatar(widget.current);
    _animal = a.animal;
    _color = a.color;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = '$_animal:$_color';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose your avatar',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AvatarWidget(avatar: value, radius: 44),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final e in avatarAnimals.keys)
                  GestureDetector(
                    onTap: () => setState(() => _animal = e),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: e == _animal ? cs.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: AvatarWidget(
                          avatar: '$e:$_color', radius: 22),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < avatarColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: avatarColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == _color ? cs.onSurface : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, value),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}