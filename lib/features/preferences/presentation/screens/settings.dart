import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/find_my/presentation/screens/item_management.dart';
import 'package:myhaystack/features/preferences/presentation/viewmodels/preferences_viewmodel.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/section_title.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with TickerProviderStateMixin {

  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final state = ref.read(preferencesViewModelProvider);
    _serverUrlController.text = state.serverUrl;
    _usernameController.text = state.username;
    _passwordController.text = state.password;
    _daysController.text = state.daysRetrieval.toString();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(preferencesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
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

          const Divider(height: 32),
          const SectionTitle(title: 'Connection Preferences'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _serverUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: viewModel.updateServerUrl,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: viewModel.updateUsername,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: viewModel.updatePassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _daysController,
                  decoration: const InputDecoration(
                    labelText: 'Days Retrieval',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      viewModel.updateDaysRetrieval(parsed);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _generateFooter(),
        ],
      ),
    );
  }

  Widget _generateFooter() {
    return Center(
      child: Column(
        children: [
          const Text("myHaystack", style: TextStyle(fontSize: 30)),
          const Text("easily manage your OpenHaystack accessories"),
          const Text("with a wonderful UI"),
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
                  }
                },
                icon: const Icon(SimpleIcons.github, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}