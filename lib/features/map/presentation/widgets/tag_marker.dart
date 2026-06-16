import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/domain/entities/tracked_item.dart';

class TagMarker extends StatelessWidget {
  final TrackedItem item;
  final bool isSelected;

  const TagMarker({
    super.key,
    required this.item,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final itemColor = Color(item.color);

    return Transform.rotate(
      angle: -math.pi / 4,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
            bottomRight: Radius.circular(50),
            bottomLeft: Radius.zero,
          ),
          border: Border.all(
            color: isSelected ? itemColor : colors.outlineVariant,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(1.5, 1.5)
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Transform.rotate(
          angle: math.pi / 4,
          child: CircleAvatar(
            backgroundColor: isSelected
                ? itemColor
                : colors.secondaryContainer,
            child: item.emoji != null && item.emoji!.trim().isNotEmpty
                ? Text(
              item.emoji!,
              style: TextStyle(fontSize: isSelected ? 22 : 14),
            )
                : Icon(
              Icons.location_on,
              color: isSelected ? Colors.white : colors.onSecondaryContainer,
              size: isSelected ? 26 : 18,
            ),
          ),
        ),
      ),
    );
  }
}
