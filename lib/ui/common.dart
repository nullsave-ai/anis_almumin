import 'dart:ui';
import 'package:flutter/material.dart';

export '../core/format.dart';

const kBg1 = Color(0xFF0A101C), kBg2 = Color(0xFF13233D);
const kAccent = Color(0xFF7DD3C0), kGold = Color(0xFFD9B872);
const kText = Color(0xFFE8EEF7), kMuted = Color(0xFF93A1B8);

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kBg2, kBg1])),
        child: child,
      );
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color(0x0FFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: r, side: const BorderSide(color: Color(0x14FFFFFF))),
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

Widget centered(Widget child) => SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: child)));

