import 'package:flutter/material.dart';
import 'package:myhaystack/core/utils/time_utils.dart';

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

    final itemColorScheme = item.getColorScheme(brightness);

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
                      Row(
                        verticalDirection: VerticalDirection.up,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: itemColorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RotatedBox(
                            quarterTurns: 1,
                            child: Icon(
                              switch (item.batteryStatus) {
                                0 => Icons.battery_full_rounded,
                                1 => Icons.battery_6_bar_rounded,
                                2 => Icons.battery_3_bar_rounded,
                                3 || _ => Icons.battery_alert_rounded,
                              },
                              color: switch (item.batteryStatus) {
                                0 => Colors.green,
                                1 => Colors.amber,
                                2 => Colors.orange,
                                3 || _ => Colors.red,
                              },
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.lastSeen?.timeAgo() ?? 'Never seen',
                        style: TextStyle(
                          fontSize: 12,
                          color: itemColorScheme.onSurfaceVariant,
                        ),
                      ),
                      // TODO: use some api to get the address of the location and other data
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(children: []),
            ],
          ),
        ),
      ),
    );
  }
}
