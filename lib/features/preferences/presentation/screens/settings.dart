import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/find_my/presentation/screens/item_management.dart';
import 'package:myhaystack/features/preferences/presentation/viewmodels/preferences_viewmodel.dart';

import '../widgets/connection_modal.dart';
import '../widgets/section_title.dart';
import '../widgets/settings_footer.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(preferencesViewModelProvider);
    _daysController.text = state.daysRetrieval.toString();
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _openConnectionModal(
    BuildContext context,
    dynamic state,
    dynamic viewModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConnectionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferencesViewModelProvider);
    final viewModel = ref.read(preferencesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                const SectionTitle(title: 'Items'),
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Manage your Items'),
                  subtitle: const Text('CRUD your Items'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ItemManagementPage(),
                      ),
                    );
                  },
                ),

                const Divider(height: 32),

                const SectionTitle(title: 'Connection Preferences'),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('Configure Server Connection'),
                  subtitle: const Text('URL, Username, and Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openConnectionModal(context, state, viewModel),
                ),

                const Divider(height: 32),

                const SectionTitle(title: 'General Preferences'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: 'Days Retrieval (Max 7)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      int? parsed = int.tryParse(value);
                      if (parsed != null) {
                        if (parsed > 7) {
                          parsed = 7;
                          _daysController.text = '7';
                          _daysController.selection =
                              TextSelection.fromPosition(
                                const TextPosition(offset: 1),
                              );
                        }
                        viewModel.updateDaysRetrieval(parsed);
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text('Auto-center map'),
                  subtitle: const Text(
                    'Automatically move to current position at startup',
                  ),
                  value: state.autoPanAtStartup ?? false,
                  onChanged: (val) {
                    viewModel.updateAutoPanAtStartup(val);
                  },
                ),
              ],
            ),
          ),
          const SettingsFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
