import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:myhaystack/features/preferences/presentation/screens/settings.dart';
import 'package:myhaystack/shared/domain/entities/tracked_item.dart';

import '../viewmodels/map_viewmodel.dart';
import '../widgets/map_action_button.dart';
import '../widgets/tag_card.dart';
import '../widgets/tag_marker.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController =
  AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    curve: Curves.easeInOutCubic,
  );

  final PageController _pageController = PageController(viewportFraction: 0.85);

  void _onPageChanged(int index) {
    ref.read(mapViewModelProvider.notifier).updateIndex(index);

    final state = ref
        .read(mapViewModelProvider)
        .value;
    if (state != null && state.items.isNotEmpty) {
      _animatedMapController.animateTo(
        dest: state.items[index].currLocation,
        zoom: 15.0,
      );
    }
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapStateAsync = ref.watch(mapViewModelProvider);

    return Scaffold(
      body: mapStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (mapState) {
          final items = mapState.items;
          final currentIndex = mapState.currentIndex;

          return Stack(
            children: [
              FlutterMap(
                mapController: _animatedMapController.mapController,
                options: MapOptions(
                  initialCenter: items.isNotEmpty
                      ? items[0].currLocation
                      : const LatLng(50.85045, 4.34878),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: "it.reloia.myhaystack",
                  ),
                  MarkerLayer(
                    markers: [
                      ...items.indexed
                          .where((record) {
                            final (index, _) = record;
                            return index != currentIndex;
                          })
                          .map((record) {
                            final (index, item) = record;
                            return _buildMarker(item, false, index);
                          }),

                      if (items.isNotEmpty)
                        _buildMarker(
                          items[currentIndex],
                          true,
                          currentIndex,
                        ),
                    ],
                  ),
                ],
              ),

              // Top Icons
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MapActionButton(
                      icon: Icons.settings,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Bottom list of tags
              if (items.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  height: 190,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return TagCard(
                        item: items[index],
                        selected: currentIndex == index,
                        onTap: () {
                          if (currentIndex != index) {
                            _pageTo(index);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(TrackedItem item, bool isSelected, int index) {
    return Marker(
      point: item.currLocation,
      alignment: Alignment.topCenter,
      width: isSelected ? 55 : 42,
      height: isSelected ? 55 : 42,
      rotate: true,
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            _pageTo(index);
          }
        },
        child: TagMarker(item: item, isSelected: isSelected),
      ),
    );
  }

  void _pageTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }
}