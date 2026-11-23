import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A square photo from a local file, decoded at thumbnail size so a full
/// camera image never sits in memory. Shows an icon if it can't be decoded.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FikraRadius.md),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: 360,
        errorBuilder: (context, _, _) => ColoredBox(
          color: context.colors.chip,
          child: Center(child: Icon(Icons.broken_image_outlined, color: context.colors.textSecondary)),
        ),
      ),
    );
  }
}
