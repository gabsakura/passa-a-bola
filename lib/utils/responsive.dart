import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utilitários para alternar entre experiência mobile e web/desktop.
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  static const double contentMaxWidth = 1280;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isWideScreen(BuildContext context) =>
      widthOf(context) >= mobileBreakpoint;

  /// Web em tela larga usa shell com sidebar; mobile e web estreito usam bottom nav.
  static bool useWebShell(BuildContext context) =>
      kIsWeb && isWideScreen(context);

  static bool useWebLogin(BuildContext context) =>
      kIsWeb && isWideScreen(context);

  static EdgeInsets pagePadding(BuildContext context) {
    if (useWebShell(context)) {
      return const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 24,
      );
    }
    return const EdgeInsets.all(16);
  }
}

/// Centraliza e limita a largura do conteúdo em telas grandes.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
        child: Padding(
          padding: padding ?? Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
