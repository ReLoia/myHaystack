import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/create_item.dart';
import '../viewmodels/item_management_viewmodel.dart';

class AddItemFAB extends ConsumerStatefulWidget {
  final bool isMenuOpen;
  final AnimationController animationController;
  final Function() toggleMenu;


  const AddItemFAB({
    super.key,
    required this.isMenuOpen,
    required this.animationController,
    required this.toggleMenu
  });

  @override
  ConsumerState<AddItemFAB> createState() => _AddItemFABState();
}

class _AddItemFABState extends ConsumerState<AddItemFAB>
    with TickerProviderStateMixin {
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;


  @override
  void initState() {
    super.initState();

    _expandAnimation = CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOutBack,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.375).animate(
      CurvedAnimation(parent: widget.animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildMenuItem(
          label: 'Import from JSON',
          icon: Icons.data_object,
          onPressed: () {
            widget.toggleMenu();
            _handleImportJson();
          },
        ),

        const SizedBox(height: 16),

        _buildMenuItem(
          label: 'Create manually',
          icon: Icons.edit_document,
          onPressed: () {
            widget.toggleMenu();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreateItemPage()));
          },
        ),

        const SizedBox(height: 16),

        FloatingActionButton.extended(
          onPressed: widget.toggleMenu,
          icon: RotationTransition(
            turns: _rotateAnimation,
            child: const Icon(Icons.add),
          ),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      alignment: Alignment.centerRight,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 16),
            FloatingActionButton.small(
              heroTag: label,
              onPressed: onPressed,
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportJson() async {
    try {
      await ref.read(itemManagementViewModelProvider.notifier).importItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items imported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
