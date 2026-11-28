import '../../core/widgets/smart_text.dart';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class ProductColorAction extends StatelessWidget {
  const ProductColorAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final Color color, foreground;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 22),
    label: SmartText(label, textAlign: TextAlign.center),
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foreground,
      textStyle: context.text.button,
      minimumSize: const Size(double.infinity, 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
