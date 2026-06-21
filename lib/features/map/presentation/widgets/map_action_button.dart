import 'package:flutter/material.dart';

class MapActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;

  const MapActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
