import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/find_my/presentation/widgets/add_item_fab.dart';

import '../viewmodels/item_management_viewmodel.dart';
import 'create_item.dart';
import 'edit_item.dart';

class ItemManagementPage extends ConsumerStatefulWidget {
  const ItemManagementPage({super.key});

  @override
  ConsumerState<ItemManagementPage> createState() => _ItemManagementPageState();
}

class _ItemManagementPageState extends ConsumerState<ItemManagementPage>
    with TickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsyncValue = ref.watch(itemManagementViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Items')),

      floatingActionButton: AddItemFAB(
        isMenuOpen: _isMenuOpen,
        animationController: _animationController,
        toggleMenu: _toggleMenu,
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isMenuOpen) _toggleMenu();
        },
        child: itemsAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'No items tracked yet.\nTap + to add one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];

                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Item?'),
                        content: Text(
                          'Are you sure you want to stop tracking "${item.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    ref
                        .read(itemManagementViewModelProvider.notifier)
                        .deleteItem(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} deleted')),
                    );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Color(item.color),
                      child: Text(
                        item.emoji ?? '',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditItemPage(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
