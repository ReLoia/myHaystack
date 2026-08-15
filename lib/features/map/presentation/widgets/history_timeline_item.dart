import 'package:flutter/material.dart';

import '../../data/models/grouped_location.dart';
import 'timeline_painter.dart';

class HistoryTimelineItem extends StatelessWidget {
  final GroupedLocation group;
  final int index;
  final int totalLength;
  final VoidCallback onTap;

  const HistoryTimelineItem({
    super.key,
    required this.group,
    required this.index,
    required this.totalLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final startTimeStr =
        "${group.startTime.hour.toString().padLeft(2, '0')}:${group.startTime.minute.toString().padLeft(2, '0')}";
    final endTimeStr =
        "${group.endTime.hour.toString().padLeft(2, '0')}:${group.endTime.minute.toString().padLeft(2, '0')}";

    final displayTimeStr = group.isGroup
        ? "$startTimeStr - $endTimeStr (${group.rawPoints.length} points grouped)"
        : "At $startTimeStr";

    final bool isEnd = index == 0;
    final bool isStart = index == totalLength - 1;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TimelinePainter(
                          isFirst: index == 0,
                          isLast: index == totalLength - 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    _buildListMarkerWidget(isStart, isEnd, theme),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 12.0,
                    bottom: 12.0,
                    right: 12.0,
                    left: 8.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lat: ${group.averageLocation.latitude.toStringAsFixed(4)}, Lng: ${group.averageLocation.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              "Accuracy: ±${group.averageAccuracy.toStringAsFixed(0)}m",
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (group.batteryIcon != null) ...[
                            const SizedBox(width: 4),
                            IconTheme(
                              data: const IconThemeData(size: 22),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: group.batteryIcon!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayTimeStr,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: group.isGroup
                              ? FontWeight.w500
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListMarkerWidget(bool isStart, bool isEnd, ThemeData theme) {
    final double radius = isEnd ? 10.0 : (isStart ? 8.0 : 4.0);
    final double diameter = radius * 2;
    final Color dotColor = isEnd
        ? Colors.red
        : (isStart ? Colors.green : Colors.blue);

    final Widget baseCircle = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );

    if (group.isGroup) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          baseCircle,
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                '${group.rawPoints.length}',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return baseCircle;
  }
}
