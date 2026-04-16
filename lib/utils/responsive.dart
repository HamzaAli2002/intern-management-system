// ─── lib/utils/responsive.dart ────────────────────────────────────────────

import 'package:flutter/material.dart';

class R {
  static const double maxW = 860.0;

  static bool isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 600;

  static double hPad(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 600) return 16;
    if (w < 960) return 24;
    return ((w - maxW) / 2).clamp(24.0, 300.0);
  }

  /// Centers & constrains content. Use for all scrollable page bodies.
  static Widget wrap({required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxW),
      child: child,
    ),
  );
}
