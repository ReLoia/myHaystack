import 'package:flutter/material.dart';

class OfflineFilter extends StatelessWidget {
  final bool isOffline;
  final Widget child;

  const OfflineFilter({
    super.key,
    required this.isOffline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return child;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, // R
        0.2126, 0.7152, 0.0722, 0, 0, // G
        0.2126, 0.7152, 0.0722, 0, 0, // B
        0,      0,      0,      1, 0,
      ]),
      child: Opacity(
        opacity: 0.65,
        child: child,
      ),
    );
  }
}
