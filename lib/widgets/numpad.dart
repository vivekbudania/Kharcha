import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Numpad extends StatelessWidget {
  final void Function(String) onKey;
  const Numpad({super.key, required this.onKey});

  static const keys = ['7','8','9','4','5','6','1','2','3','.','0','⌫'];

  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3, childAspectRatio: 2.2, mainAxisSpacing: 8, crossAxisSpacing: 8,
    children: keys.map((k) => _Key(k: k, onTap: () => onKey(k))).toList(),
  );
}

class _Key extends StatelessWidget {
  final String k;
  final VoidCallback onTap;
  const _Key({required this.k, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Center(child: k == '⌫'
          ? const Icon(Icons.backspace_outlined, size: 18)
          : Text(k, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
    ),
  );
}
