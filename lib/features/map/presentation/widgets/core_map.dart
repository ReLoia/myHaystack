import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class CoreMap extends StatelessWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final List<Widget> layers;
  final VoidCallback? onMapReady;

  const CoreMap({
    super.key,
    required this.mapController,
    required this.initialCenter,
    this.initialZoom = 15.0,
    required this.layers,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        maxZoom: 20,
        minZoom: 4,
        onMapReady: onMapReady,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-90, -180),
            const LatLng(90, 180),
          ),
        ),
      ),
      children: [
        TileLayer(
          tileProvider: FMTCTileProvider(
            stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
          ),
          tileBuilder: (context, child, tile) {
            return isDark
                ? ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                -.98, 0, 0, 0, 255, // R
                0, -.98, 0, 0, 255, // G
                0, 0, -.98, 0, 255, // B
                0, 0, 0, 1, 0,
              ]),
              child: child,
            )
                : child;
          },
          tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 150)),
          panBuffer: 2,
          urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          // subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: "it.reloia.myhaystack",
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
            TextSourceAttribution(
              '© CARTO',
              onTap: () => launchUrl(Uri.parse('https://carto.com/attributions')),
            ),
          ],
        ),
        ...layers,
      ],
    );
  }
}