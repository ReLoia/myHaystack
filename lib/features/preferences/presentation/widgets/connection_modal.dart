import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/preferences/presentation/viewmodels/preferences_viewmodel.dart';
import 'package:myhaystack/shared/presentation/providers/app_providers.dart';

class ConnectionModal extends ConsumerStatefulWidget {
  const ConnectionModal({super.key});

  @override
  ConsumerState<ConnectionModal> createState() => _ConnectionModalState();
}

class _ConnectionModalState extends ConsumerState<ConnectionModal> {
  late TextEditingController _urlController;
  late TextEditingController _userController;
  late TextEditingController _passController;

  bool _isChecking = false;
  bool _checkSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final prefsState = ref.read(preferencesViewModelProvider);

    _urlController = TextEditingController(text: prefsState.serverUrl);
    _userController = TextEditingController(text: prefsState.username);
    _passController = TextEditingController(text: prefsState.password);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
      _checkSuccess = false;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(maclessHaystackAPIServiceProvider);

      final success = await apiService.checkConnection(
        serverUrl: _urlController.text.trim(),
        username: _userController.text.trim(),
        password: _passController.text.trim(),
      );

      setState(() {
        _isChecking = false;
        _checkSuccess = success;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _checkSuccess = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  void _onInputChanged(String _) {
    if (_checkSuccess || _errorMessage != null) {
      setState(() {
        _checkSuccess = false;
        _errorMessage = null;
      });
    }
  }

  void _savePreferences() {
    final viewModel = ref.read(preferencesViewModelProvider.notifier);

    viewModel.updateServerUrl(_urlController.text.trim());
    viewModel.updateUsername(_userController.text.trim());
    viewModel.updatePassword(_passController.text.trim());

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server Connection'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: _onInputChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              onChanged: _onInputChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: _onInputChanged,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            if (_checkSuccess) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Connection Successful!",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_checkSuccess)
          ElevatedButton(
            onPressed: _urlController.text.isEmpty || _isChecking
                ? null
                : _checkConnection,
            child: _isChecking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Check Connection'),
          ),
        if (_checkSuccess)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: _savePreferences,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}
