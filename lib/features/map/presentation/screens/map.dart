import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:myhaystack/features/preferences/presentation/screens/settings.dart';
import 'package:myhaystack/shared/domain/entities/tracked_item.dart';

import '../viewmodels/map_viewmodel.dart';
import '../widgets/map_action_button.dart';
import '../widgets/tag_card.dart';
import '../widgets/tag_marker.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapViewModel _viewModel = MapViewModel();

  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(
        vsync: this,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
      );

  final PageController _pageController = PageController(viewportFraction: 0.85);

  void _onPageChanged(int index) {
    _viewModel.updateIndex(index);

    _animatedMapController.animateTo(
      dest: _viewModel.items[index].location,
      zoom: 15.0,
    );
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _animatedMapController.mapController,
                options: MapOptions(
                  initialCenter: _viewModel.items.isNotEmpty
                      ? _viewModel.items[0].location
                      : const LatLng(0, 0),
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
                      ..._viewModel.items.indexed
                          .where((record) {
                            final (index, _) = record;
                            return index != _viewModel.currentIndex;
                          })
                          .map((record) {
                            final (index, item) = record;
                            return _buildMarker(item, false, index);
                          }),

                      if (_viewModel.items.isNotEmpty)
                        _buildMarker(
                          _viewModel.items[_viewModel.currentIndex],
                          true,
                          _viewModel.currentIndex,
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
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _viewModel.items.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return TagCard(
                      item: _viewModel.items[index],
                      selected: _viewModel.currentIndex == index,
                      onTap: () {
                        if (_viewModel.currentIndex != index) {
                          _pageTo(index);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _buildMarker(TrackedItem item, bool isSelected, int index) {
    return Marker(
      point: item.location,
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
