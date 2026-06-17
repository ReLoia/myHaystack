import 'package:flutter/material.dart';

import '../../../../shared/domain/entities/tracked_item.dart';

class TagCard extends StatelessWidget {
  final TrackedItem item;
  final bool selected;
  final Function() onTap;

  const TagCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final itemColor = Color(item.color);

    final itemColorScheme = ColorScheme.fromSeed(
      seedColor: itemColor,
      brightness: brightness,
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.fromLTRB(8, selected ? 4 : 12, 8, selected ? 8 : 4),
        elevation: 6,
        color: itemColorScheme.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: itemColorScheme.primaryContainer,
                    child: item.emoji != null && item.emoji!.trim().isNotEmpty
                        ? Text(
                            item.emoji!,
                            style: const TextStyle(fontSize: 20),
                          )
                        : Icon(
                            Icons.location_on,
                            color: itemColorScheme.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: itemColorScheme.onSurface,
                        ),
                      ),
                      // TODO: use some api to get the address of the location and other data
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: itemColorScheme.primary,
                        foregroundColor: itemColorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.volume_up, size: 18),
                      label: const Text("Play Sound"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
