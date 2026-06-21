import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/preferences/presentation/widgets/section_title.dart';
import 'package:myhaystack/shared/domain/entities/tracked_item.dart';

import '../viewmodels/item_management_viewmodel.dart';

class EditItemPage extends ConsumerStatefulWidget {
  final TrackedItem item;

  const EditItemPage({super.key, required this.item});

  @override
  ConsumerState<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends ConsumerState<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String? _emoji;
  late Color _selectedColor;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _name = widget.item.name;
    _emoji = widget.item.emoji;
    _selectedColor = Color(widget.item.color);
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isSaving = true);

      try {
        final updatedItem = TrackedItem(
          id: widget.item.id,
          name: _name,
          publicKey: widget.item.publicKey,
          color: _selectedColor.toARGB32(),
          currLocation: widget.item.currLocation,
          emoji: _emoji,
          orderIndex: widget.item.orderIndex,
          accuracy: widget.item.accuracy,
          batteryStatus: widget.item.batteryStatus,
          lastSeen: widget.item.lastSeen,
        );

        await ref
            .read(itemManagementViewModelProvider.notifier)
            .updateItem(updatedItem);

        if (mounted) {
          setState(() => _hasChanges = false);
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update item: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _showColorPicker() {
    Color tempColor = _selectedColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a marker color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) => tempColor = color,
              enableAlpha: false,
              displayThumbColor: true,
              hexInputBar: true,
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
                setState(() {
                  _selectedColor = tempColor;
                  _hasChanges = true;
                });
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
    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Would you like to save them before leaving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('discard'),
                child: const Text('No, discard'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop('save'),
                child: const Text('Yes, save'),
              ),
            ],
          ),
        );

        if (action == 'discard') {
          if (context.mounted) {
            setState(() => _hasChanges = false);
            Navigator.of(context).pop();
          }
        } else if (action == 'save') {
          await _updateItem();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Item'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'View Location History',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History page coming soon!')),
                );
              },
            ),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _isSaving ? null : _updateItem,
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'export') {
                  await ref
                      .read(itemExportServiceProvider)
                      .exportSingleItemToJson(widget.item);
                } else if (value == 'share') {
                  await ref
                      .read(itemExportServiceProvider)
                      .shareSingleItem(widget.item);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt),
                      SizedBox(width: 8),
                      Text('Save to Device'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share to App'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  initialValue: _name,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _hasChanges = true),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Please enter a name'
                      : null,
                  onSaved: (value) => _name = value!.trim(),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  initialValue: _emoji,
                  enabled: !_isSaving,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    labelText: 'Emoji (Optional)',
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _hasChanges = true),
                  onSaved: (value) => _emoji = value?.trim(),
                ),

                const SizedBox(height: 24),
                const SectionTitle(title: 'Appearance'),
                const SizedBox(height: 4),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marker Color'),
                  subtitle: const Text('Tap to change the color'),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                  ),
                  onTap: _isSaving ? null : _showColorPicker,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
