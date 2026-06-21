import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/preferences/presentation/widgets/section_title.dart';

import '../viewmodels/item_management_viewmodel.dart';

class CreateItemPage extends ConsumerStatefulWidget {
  const CreateItemPage({super.key});

  @override
  ConsumerState<CreateItemPage> createState() => CreateItemPageState();
}

class CreateItemPageState extends ConsumerState<CreateItemPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _privateKey = '';
  String? _emoji;
  Color _selectedColor = Colors.blue;

  bool _isSaving = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isSaving = true);

      try {
        await ref
            .read(itemManagementViewModelProvider.notifier)
            .addItem(
              name: _name,
              privateKey: _privateKey,
              color: _selectedColor.value,
              emoji: _emoji,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _showColorPicker() {
    // Store the color temporarily in case the user cancels the dialog
    Color tempColor = _selectedColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a marker color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (Color color) {
                tempColor = color; // Update temp color while sliding
              },
              enableAlpha: false, // Prevents transparent map markers
              displayThumbColor: true,
              hexInputBar: true, // Shows the hex input field
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Select'),
              onPressed: () {
                setState(() => _selectedColor = tempColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a new Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Item Details'),
              const SizedBox(height: 16),

              TextFormField(
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. My Keys',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Please enter a name'
                    : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Private Key',
                  hintText: 'Enter the key',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Please enter the private key'
                    : null,
                onSaved: (value) => _privateKey = value!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                enabled: !_isSaving,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'Emoji (Optional)',
                  hintText: '🎒',
                  prefixIcon: Icon(Icons.emoji_emotions_outlined),
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _emoji = value?.trim(),
              ),

              const SizedBox(height: 24),
              const SectionTitle(title: 'Appearance'),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marker Color'),
                subtitle: const Text('Tap to choose a color for the map'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                onTap: _isSaving ? null : _showColorPicker,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
