import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.acento,
    this.blur = false,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? acento;
  final bool
  blur; // BackdropFilter es costoso: úsalo solo donde haya algo detrás.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);
    Widget w = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radio,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (acento ?? Colors.white).withValues(
              alpha: acento == null ? 0.08 : 0.14,
            ),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: (acento ?? Colors.white).withValues(
            alpha: acento == null ? 0.10 : 0.35,
          ),
        ),
      ),
      child: child,
    );
    if (blur) {
      w = ClipRRect(
        borderRadius: radio,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: w,
        ),
      );
    }
    if (onTap != null) {
      w = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radio, onTap: onTap, child: w),
      );
    }
    return w;
  }
}
