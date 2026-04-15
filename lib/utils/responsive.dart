import 'package:flutter/material.dart';

/// ── Responsive Design Utilities ─────────────────────────────────────────
class ResponsiveHelper {
  /// Device Size Classifications
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1600;

  /// Screen Dimensions
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Responsive Sizing
  static double hp(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * (percentage / 100);

  static double wp(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * (percentage / 100);

  /// Responsive Font Sizes
  static double fontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isDesktop(context)) return desktopSize ?? mobileSize * 1.2;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.1;
    return mobileSize;
  }

  /// Responsive Padding
  static EdgeInsets padding(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final pad = isDesktop(context)
        ? desktop ?? mobile * 1.5
        : isTablet(context)
            ? tablet ?? mobile * 1.2
            : mobile;
    return EdgeInsets.all(pad);
  }

  static EdgeInsets paddingSymmetric(
    BuildContext context, {
    required double mobileH,
    required double mobileV,
    double? tabletH,
    double? tabletV,
    double? desktopH,
    double? desktopV,
  }) {
    final h = isDesktop(context)
        ? desktopH ?? mobileH * 1.5
        : isTablet(context)
            ? tabletH ?? mobileH * 1.2
            : mobileH;
    final v = isDesktop(context)
        ? desktopV ?? mobileV * 1.5
        : isTablet(context)
            ? tabletV ?? mobileV * 1.2
            : mobileV;
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  /// Responsive Border Radius
  static BorderRadius radius(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final rad = isDesktop(context)
        ? desktop ?? mobile * 1.2
        : isTablet(context)
            ? tablet ?? mobile * 1.1
            : mobile;
    return BorderRadius.circular(rad);
  }

  /// Grid/Layout Columns
  static int gridColumns(BuildContext context) {
    if (isLargeDesktop(context)) return 4;
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Responsive Width Constraints
  static double maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isDesktop(context)) return 1000;
    if (isTablet(context)) return width * 0.9;
    return width * 0.95;
  }

  /// Responsive Icon Size
  static double iconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return fontSize(context,
        mobileSize: mobile, tabletSize: tablet, desktopSize: desktop);
  }

  /// Orientation Check
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Device Type Name
  static String deviceType(BuildContext context) {
    if (isDesktop(context)) return 'Desktop';
    if (isTablet(context)) return 'Tablet';
    return 'Mobile';
  }
}

/// ── Responsive Container Widget ─────────────────────────────────────────
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.maxWidth,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: alignment,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth(context),
          ),
          child: Padding(
            padding: padding ??
                ResponsiveHelper.paddingSymmetric(
                  context,
                  mobileH: 16,
                  mobileV: 20,
                  tabletH: 24,
                  tabletV: 28,
                  desktopH: 32,
                  desktopV: 40,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ── Responsive Grid Widget ──────────────────────────────────────────────
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.padding,
    this.spacing,
    this.runSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cols = ResponsiveHelper.gridColumns(context);
    final gap = spacing ?? (ResponsiveHelper.isDesktop(context) ? 24 : 16);

    return Padding(
      padding: padding ??
          ResponsiveHelper.paddingSymmetric(
            context,
            mobileH: 12,
            mobileV: 12,
            tabletH: 16,
            desktopH: 20,
          ),
      child: Wrap(
        spacing: gap,
        runSpacing: runSpacing ?? gap,
        children: children.asMap().entries.map((entry) {
          final child = entry.value;
          final width = (ResponsiveHelper.screenWidth(context) -
                  (padding?.horizontal ?? 24) -
                  (gap * (cols - 1))) /
              cols;

          return SizedBox(
            width: width,
            child: child,
          );
        }).toList(),
      ),
    );
  }
}

/// ── Responsive Text Widget ──────────────────────────────────────────────
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseSize = mobileSize ?? 14;
    final size = ResponsiveHelper.fontSize(
      context,
      mobileSize: baseSize,
      tabletSize: tabletSize,
      desktopSize: desktopSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: size),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// ── Responsive Button ───────────────────────────────────────────────────
class ResponsiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final IconData? icon;

  const ResponsiveButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final btnHeight = height ?? (isMobile ? 48 : 52);
    final btnWidth = width ?? (icon != null ? 56 : double.infinity);
    final btnPadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 32, vertical: 14);

    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : null,
        label: ResponsiveText(
          label,
          mobileSize: 14,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: btnPadding,
        ),
      ),
    );
  }
}
