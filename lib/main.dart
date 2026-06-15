import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:myhaystack/features/map/presentation/pages/map.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _defaultLightColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent);
  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepOrangeAccent,
      brightness: Brightness.dark
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // TODO: add providers
      providers: [
        ChangeNotifierProvider(create: (_) => null),
      ],
      child: DynamicColorBuilder(
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
      ),
    );
  }
}

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    precacheImage(const AssetImage('assets/myhaystack-icon.png'), context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return const MapPage();
  }
}
