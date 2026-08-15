import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/domain/entities/tracked_item.dart';
import '../utils/map_math_utils.dart';
import '../viewmodels/item_history_viewmodel.dart';
import '../widgets/core_map.dart';
import '../widgets/history_bottom_sheet.dart';

class ItemHistoryScreen extends ConsumerStatefulWidget {
  final TrackedItem item;

  const ItemHistoryScreen({super.key, required this.item});

  @override
  ConsumerState<ItemHistoryScreen> createState() => _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends ConsumerState<ItemHistoryScreen>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(
        vsync: this,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
      );

  double _currentSheetExtent = 0.4;

  @override
  void initState() {
    super.initState();
    ref.listenManual(selectedDateProvider(widget.item.id), (previous, next) {
      final viewData = ref
          .read(itemHistoryViewDataProvider(widget.item.id))
          .value;
      if (viewData != null && viewData.groupedLocations.isNotEmpty) {
        _animatedMapController.animateTo(
          dest: viewData.groupedLocations.last.averageLocation,
        );
      }
    });
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewDataAsync = ref.watch(
      itemHistoryViewDataProvider(widget.item.id),
    );

    return Scaffold(
      appBar: AppBar(title: Text('${widget.item.name} History')),
      body: Stack(
        children: [
          viewDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (viewData) {
              final latLngPoints = viewData.groupedLocations
                  .map((g) => g.averageLocation)
                  .toList();

              if (latLngPoints.isEmpty) {
                return const Center(
                  child: Text('No history found for this date.'),
                );
              }

              return CoreMap(
                mapController: _animatedMapController.mapController,
                initialCenter: latLngPoints.last,
                layers: [
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: viewData.smoothLinePoints,
                        color: theme.colorScheme.primary,
                        strokeWidth: 4.0,
                        pattern: StrokePattern.dashed(segments: [2, 5]),
                      ),
                    ],
                  ),
                  MarkerLayer(markers: _buildMapMarkers(latLngPoints)),
                ],
              );
            },
          ),

          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _currentSheetExtent = notification.extent;
              return true;
            },
            child: HistoryBottomSheet(
              item: widget.item,
              onLocationTapped: _handleMapZoomLogic,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapZoomLogic(LatLng targetLocation) {
    final camera = _animatedMapController.mapController.camera;
    final currentZoom = camera.zoom;
    final currentCenter = camera.center;

    const distanceCalc = Distance();
    final distanceToTarget = distanceCalc.as(
      LengthUnit.Meter,
      currentCenter,
      targetLocation,
    );

    final double targetZoom;
    if (distanceToTarget < 20.0) {
      targetZoom = 17.0;
    } else {
      targetZoom = currentZoom >= 19.0 ? currentZoom : 19.0;
    }

    LatLng destination = targetLocation;

    if (_currentSheetExtent <= 0.6) {
      final screenHeight = MediaQuery.of(context).size.height;
      final sheetHeightPixels = screenHeight * _currentSheetExtent;
      final offsetYPixels = sheetHeightPixels / 2;

      destination = MapMathUtils.offsetLatLngForDrawer(
        targetLocation,
        offsetYPixels,
        targetZoom,
      );
    }

    _animatedMapController.animateTo(dest: destination, zoom: targetZoom);
  }

  List<Marker> _buildMapMarkers(List<LatLng> points) {
    List<Marker> markers = [];

    for (int i = 0; i < points.length; i++) {
      final isStart = i == 0;
      final isEnd = i == points.length - 1;

      final double radius = isEnd ? 10.0 : (isStart ? 8.0 : 4.0);
      final double diameter = radius * 2;
      final Color dotColor = isEnd
          ? Colors.red
          : (isStart ? Colors.green : Colors.blue);

      markers.add(
        Marker(
          point: points[i],
          width: diameter,
          height: diameter,
          child: Container(
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      );
    }
    return markers;
  }
}
