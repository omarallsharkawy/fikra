import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'product_widgets.dart' show productContentDirection;

/// Color is presentation supplied by a category adapter, never inferred here.
class ProductIdeaCard extends StatelessWidget {
  const ProductIdeaCard({
    super.key,
    required this.title,
    required this.content,
    required this.onOpen,
    this.caption,
    this.timestamp,
    this.trailing,
    this.color,
    this.foreground,
  });
  final String title, content;
  final String? caption, timestamp;
  final VoidCallback onOpen;
  final Widget? trailing;
  final Color? color, foreground;

  @override
  Widget build(BuildContext context) {
    final ink = foreground ?? context.colors.onBrandBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color ?? context.colors.brandBlue,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (caption != null || trailing != null)
                  Row(
                    children: [
                      if (caption != null)
                        Expanded(
                          child: Text(
                            caption!,
                            style: context.text.meta.copyWith(color: ink, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ?trailing,
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textDirection: productContentDirection(title),
                  style: context.text.cardTitle.copyWith(color: ink),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  textDirection: productContentDirection(content),
                  style: context.text.caption.copyWith(color: ink),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 10),
                  Text(timestamp!, style: context.text.meta.copyWith(color: ink)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
