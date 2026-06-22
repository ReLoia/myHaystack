import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:myhaystack/features/preferences/presentation/screens/settings.dart';
import 'package:myhaystack/features/preferences/presentation/viewmodels/preferences_viewmodel.dart';
import 'package:myhaystack/shared/domain/entities/tracked_item.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/location_service.dart';
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

  late final AnimationController _locationAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // This fixes a weird bug with the AnimationController making the app crash. idk why
  late final AnimationController _refreshAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  bool _isLocating = false;
  bool _isSyncing = false;
  int? _syncResult;

  void _onPageChanged(int index) {
    ref.read(mapViewModelProvider.notifier).updateIndex(index);

    final state = ref.read(mapViewModelProvider).value;
    if (state != null &&
        state.items.isNotEmpty &&
        !state.items[index].hasNoData) {
      _animatedMapController.animateTo(
        dest: state.items[index].currLocation,
        zoom: 17.0,
      );
    }
  }

  Future<bool> _moveToUser() async {
    if (_isLocating) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLocating = true;
        });
        _locationAnimController.repeat(reverse: true);
      }
    });

    final locationService = ref.read(locationServiceProvider);
    final userPos = await locationService.getUserLocation();

    if (userPos != null) {
      _animatedMapController.animateTo(dest: userPos, zoom: 15.0);
      await Future.delayed(const Duration(milliseconds: 750));
    }

    if (mounted) {
      _locationAnimController.stop();
      _locationAnimController.reset();
      setState(() {
        _isLocating = false;
      });
    }

    return userPos != null;
  }

  Future<void> _syncLocations() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncResult = null;
    });

    _refreshAnimController.repeat();

    final newItemsCount = await ref
        .read(mapViewModelProvider.notifier)
        .syncLocations();

    if (!mounted) return;

    _refreshAnimController.stop();
    _refreshAnimController.reset();

    if (newItemsCount > 0) {
      setState(() {
        _syncResult = newItemsCount;
      });

      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      setState(() {
        _syncResult = null;
        _isSyncing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasRun = ref.read(initialSyncProvider);

      if (!hasRun) {
        ref.read(initialSyncProvider.notifier).markAsRun();

        _syncLocations();
      }
    });
  }

  @override
  void dispose() {
    _locationAnimController.dispose();
    _refreshAnimController.dispose();
    _animatedMapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapStateAsync = ref.watch(mapViewModelProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final userPreferences = ref.watch(preferencesViewModelProvider);
    ColorScheme colorScheme = Theme.of(context).colorScheme;

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
                  onMapReady: () {
                    if (userPreferences.autoPanAtStartup) {
                      _moveToUser();
                    }
                  },
                  maxZoom: 20,
                  minZoom: 4,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-90, -180),
                      const LatLng(90, 180),
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    // based on: https://github.com/seemoo-lab/openhaystack/blob/main/openhaystack-mobile/lib/map/map.dart#L105-L117
                    tileProvider: NetworkTileProvider(),
                    tileBuilder: (context, child, tile) {
                      var isDark =
                          (Theme.of(context).brightness == Brightness.dark);
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
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: "it.reloia.myhaystack",
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                        ),
                      ),
                      TextSourceAttribution(
                        '© CARTO',
                        onTap: () => launchUrl(
                          Uri.parse('https://carto.com/attributions'),
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final camera = MapCamera.of(context);
                      final currentZoom = camera.zoom;

                      return CircleLayer(
                        circles: items.map((item) {
                          final double radiusInMeters = (item.accuracy ?? 0)
                              .toDouble();

                          final bool shouldShowCircle =
                              currentZoom > 8 && radiusInMeters > 5;

                          final itemColorScheme = item.getColorScheme(
                            Theme.of(context).brightness,
                          );

                          return CircleMarker(
                            point: item.currLocation,
                            color: itemColorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderColor: itemColorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                            borderStrokeWidth: 1.5,
                            radius: shouldShowCircle ? radiusInMeters : 0,
                            useRadiusInMeter: true,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      if (userLocationAsync.value != null)
                        Marker(
                          point: userLocationAsync.value!,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // All the items except the noData ones
                      ...items.indexed
                          .where((record) {
                            final (index, item) = record;
                            return !item.hasNoData && index != currentIndex;
                          })
                          .map((record) {
                            final (index, item) = record;
                            return _buildMarker(item, false, index);
                          }),
                      if (items.isNotEmpty)
                        _buildMarker(items[currentIndex], true, currentIndex),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        MapActionButton(
                          icon: Icons.settings,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                            CurvedAnimation(
                              parent: _locationAnimController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: MapActionButton(
                            icon: Icons.my_location,
                            onPressed: () async {
                              if (!await _moveToUser()) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not get user location',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            size: 38,
                          ),
                        ),
                        _buildAnimatedRefreshButton(colorScheme),
                      ],
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

  Widget _buildAnimatedRefreshButton(ColorScheme colorScheme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: _syncResult != null
          ? Container(
              key: const ValueKey('text'),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '+$_syncResult',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : Container(
              key: const ValueKey('icon'),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _isSyncing ? null : _syncLocations,
                  child: Center(
                    child: RotationTransition(
                      turns: _refreshAnimController,
                      child: const Icon(Icons.refresh, size: 22),
                    ),
                  ),
                ),
              ),
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

class InitialSyncNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markAsRun() {
    state = true;
  }
}

final initialSyncProvider = NotifierProvider<InitialSyncNotifier, bool>(() {
  return InitialSyncNotifier();
});
