import 'package:flutter/material.dart';
import 'package:myhaystack/features/find_my/presentation/screens/item_management.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/section_title.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const SectionTitle(title: 'Items'),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Manage your Items'),
            subtitle: const Text('CRUD your Items'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ItemManagementPage()),
              );
            },
          ),
          _generateFooter(),
        ],
      ),
    );
  }

  Widget _generateFooter() {
    return Center(
      child: Column(
        children: [
          Text("myHaystack", style: TextStyle(fontSize: 30)),
          Text("easily manage your OpenHaystack accessories"),
          Text("with a wonderful UI"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  final Uri uri = Uri.parse(
                    'https://github.com/ReLoia/myHaystack',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    // TODO
                  }
                },
                icon: Icon(SimpleIcons.github, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
