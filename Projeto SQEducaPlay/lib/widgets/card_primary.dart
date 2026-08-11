import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class CardPrimary extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CardPrimary({super.key, required this.child, this.padding, this.elevation = 2.0, this.onTap, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final container = Container(
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusMD),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: elevation, offset: const Offset(0, 1)),
        ],
      ),
      padding: padding ?? EdgeInsets.all(DesignTokens.spaceMD),
      child: child,
    );

    if (onTap != null) return GestureDetector(onTap: onTap, child: container);
    return container;
  }
}
