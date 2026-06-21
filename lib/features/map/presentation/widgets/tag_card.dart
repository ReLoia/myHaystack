import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/core/utils/time_utils.dart';
import 'package:myhaystack/shared/widgets/offline_filter.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import for Maps

import '../../../../shared/domain/entities/tracked_item.dart';
import '../../../../shared/presentation/providers/geocoding_cache_provider.dart';
import '../../../find_my/presentation/screens/edit_item.dart';

class TagCard extends ConsumerWidget {
  final TrackedItem item;
  final bool selected;
  final VoidCallback onTap;

  const TagCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final itemColorScheme = item.getColorScheme(brightness);

    final (batteryIcon, batteryColor) = switch (item.batteryStatus) {
      0 => (Icons.battery_full_rounded, Colors.green),
      1 => (Icons.battery_6_bar_rounded, Colors.amber),
      2 => (Icons.battery_3_bar_rounded, Colors.orange),
      _ => (Icons.battery_alert_rounded, Colors.red),
    };

    String addressText = 'No location';
    final hasLocation =
        item.currLocation.latitude != 0 && item.currLocation.longitude != 0;

    if (hasLocation) {
      final cacheNotifier = ref.read(geocodingCacheProvider.notifier);
      final cacheKey = cacheNotifier.getCacheKey(item.currLocation);

      final cacheMap = ref.watch(geocodingCacheProvider);

      if (cacheMap.containsKey(cacheKey)) {
        addressText = cacheMap[cacheKey]!;
      } else {
        addressText = 'Loading address...';
        Future.microtask(() => cacheNotifier.fetchAddress(item.currLocation));
      }
    }

    final hasEmoji = item.emoji != null && item.emoji!.trim().isNotEmpty;

    final buttonStyle = IconButton.styleFrom(
      backgroundColor: itemColorScheme.secondaryContainer,
      foregroundColor: itemColorScheme.onSecondaryContainer,
      padding: const EdgeInsets.all(12),
    );

    return GestureDetector(
      onTap: onTap,
      child: OfflineFilter(
        isOffline: item.isOffline,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.fromLTRB(
            8,
            selected ? 4 : 12,
            8,
            selected ? 12 : 4,
          ),
          decoration: BoxDecoration(
            color: itemColorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.15 : 0.05),
                blurRadius: selected ? 16 : 6,
                spreadRadius: selected ? 1 : 0,
                offset: Offset(0, selected ? 8 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: itemColorScheme.primaryContainer,
                      child: hasEmoji
                          ? Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.emoji!,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.location_on,
                              color: itemColorScheme.onPrimaryContainer,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: itemColorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              RotatedBox(
                                quarterTurns: 1,
                                child: Icon(
                                  batteryIcon,
                                  color: batteryColor,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            addressText,
                            style: TextStyle(
                              fontSize: 12,
                              color: itemColorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.lastSeen?.timeAgo() ?? 'Never seen',
                            style: TextStyle(
                              fontSize: 12,
                              color: itemColorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Location History',
                      style: buttonStyle,
                      icon: const Icon(Icons.history_rounded),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Location history coming in the future!",
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    IconButton.filledTonal(
                      tooltip: 'Open in Maps',
                      style: buttonStyle,
                      icon: const Icon(Icons.directions_rounded),
                      onPressed: !hasLocation
                          ? null
                          : () async {
                              final lat = item.currLocation.latitude;
                              final lng = item.currLocation.longitude;

                              final mapUrl = Uri.parse(
                                'https://maps.google.com/?q=$lat,$lng',
                              );

                              if (await canLaunchUrl(mapUrl)) {
                                await launchUrl(
                                  mapUrl,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open map application.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                    ),

                    IconButton.filledTonal(
                      tooltip: 'Item Settings',
                      style: buttonStyle,
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditItemPage(item: item),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
