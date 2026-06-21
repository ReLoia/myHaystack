import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/features/find_my/presentation/widgets/add_item_fab.dart';

import '../viewmodels/item_management_viewmodel.dart';
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
      appBar: AppBar(
        title: const Text('Manage Items'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final items = ref.read(itemManagementViewModelProvider).value;
              if (items == null || items.isEmpty) return;

              if (value == 'export') {
                await ref.read(itemExportServiceProvider).exportItemsToJson(items);
              } else if (value == 'share') {
                await ref.read(itemExportServiceProvider).shareItems(items);
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

            return ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: items.length,
              onReorderItem: (oldIndex, newIndex) {
                ref
                    .read(itemManagementViewModelProvider.notifier)
                    .reorderItems(oldIndex, newIndex);
              },
              buildDefaultDragHandles: false,
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
                  },
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.drag_handle, color: Colors.grey),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Color(item.color),
                              child: item.emoji != null && item.emoji!.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          item.emoji!,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
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
                      if (index < items.length - 1) const Divider(height: 1),
                    ],
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
