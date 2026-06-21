import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:myhaystack/features/map/presentation/screens/map.dart';
import 'package:myhaystack/shared/presentation/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/find_my/presentation/viewmodels/item_management_viewmodel.dart';
import 'features/map/presentation/viewmodels/map_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepOrangeAccent,
  );
  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepOrangeAccent,
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
            useMaterial3: true,
          ),
          home: const AppLayout(),
        );
      },
    );
  }
}

class AppLayout extends ConsumerStatefulWidget {
  const AppLayout({super.key});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapViewModelProvider.notifier).syncLocations();
    });

    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedFile> value) {
            _handleSharedFiles(value);
          },
          onError: (err) {
            debugPrint("getIntentDataStream error: $err");
          },
        );

    FlutterSharingIntent.instance.getInitialSharing().then((
      List<SharedFile> value,
    ) {
      _handleSharedFiles(value);
    });
  }

  Future<void> _handleSharedFiles(List<SharedFile> files) async {
    if (files.isEmpty) return;

    for (var sharedFile in files) {
      final filePath = sharedFile.value;

      if (filePath != null && filePath.toLowerCase().endsWith('.json')) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            final content = await file.readAsString();

            await ref
                .read(itemManagementViewModelProvider.notifier)
                .importJsonContent(content);
          }
        } catch (e) {
          debugPrint("Error reading imported JSON file: $e");
        }
      }
    }

    FlutterSharingIntent.instance.reset();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MapPage();
  }
}
