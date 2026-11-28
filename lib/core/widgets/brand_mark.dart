import 'package:flutter/material.dart';

/// Decorative brand artwork. The adjacent screen/app title supplies its label.
class FikraBrandMark extends StatelessWidget {
  const FikraBrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    Theme.of(context).brightness == Brightness.dark
        ? 'assets/icons/fikrah-icon-dark-mode.png'
        : 'assets/icons/fikrah-icon-light-mode.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    matchTextDirection: false,
  );
}
