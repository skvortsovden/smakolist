import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/shopping_list.dart';
import '../providers/app_provider.dart';
import 'add_edit_shopping_list_screen.dart';

class ShoppingListDetailScreen extends StatelessWidget {
  final String listId;
  const ShoppingListDetailScreen({super.key, required this.listId});

  ShoppingList? _list(AppProvider p) {
    try {
      return p.shoppingLists.firstWhere((l) => l.id == listId);
    } catch (_) {
      return null;
    }
  }

  void _copyToClipboard(BuildContext context, ShoppingList list) {
    final lines = list.items.map((i) {
      final qty = i.quantity == null
          ? ''
          : ' — ${i.quantity! % 1 == 0 ? i.quantity!.toInt() : i.quantity}${i.unit.isNotEmpty ? ' ${i.unit}' : ''}';
      return '${i.checked ? '✓' : '•'} ${i.name}$qty';
    }).join('\n');
    final text = '${list.name}\n$lines';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.shoppingCopiedSnack,
            style: const TextStyle(fontFamily: 'FixelText')),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _duplicateList(BuildContext context, AppProvider provider, ShoppingList list) {
    HapticFeedback.mediumImpact();
    final existing = provider.shoppingLists.map((l) => l.name).toSet();
    var name = list.name;
    var counter = 1;
    while (existing.contains(name)) {
      name = '${list.name} ($counter)';
      counter++;
    }
    final now = DateTime.now();
    final copy = ShoppingList(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      items: list.items
          .map((i) => ShoppingItem(
                id: '${now.microsecondsSinceEpoch}${i.id}',
                name: i.name,
                quantity: i.quantity,
                unit: i.unit,
              ))
          .toList(),
    );
    provider.addShoppingList(copy);
    Navigator.of(context).pop();
  }

  Future<void> _deleteList(BuildContext context, AppProvider provider, ShoppingList list) async {
    await Future.microtask(() {});
    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(S.shoppingDeleteTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(S.shoppingDeleteBody,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.shoppingDeleteConfirm),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(S.shoppingDeleteCancel,
                    style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      HapticFeedback.mediumImpact();
      provider.deleteShoppingList(list.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final list = _list(provider);
        if (list == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        list.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditShoppingListScreen(list: list),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                // Items (scrollable)
                Expanded(
                  child: list.items.isEmpty
                      ? const _EmptyItems()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 8),
                          children: list.items
                              .map((item) => _ItemTile(
                                    item: item,
                                    onToggle: () {
                                      HapticFeedback.selectionClick();
                                      item.checked = !item.checked;
                                      provider.updateShoppingList(list);
                                    },
                                    onDelete: () {
                                      HapticFeedback.mediumImpact();
                                      list.items.removeWhere((i) => i.id == item.id);
                                      provider.updateShoppingList(list);
                                    },
                                  ))
                              .toList(),
                        ),
                ),
                // Fixed action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      _ActionButton(
                        icon: Icons.content_paste_outlined,
                        label: S.shoppingCopyClipboardBtn,
                        onTap: () => _copyToClipboard(context, list),
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        label: S.shoppingRemoveBtn,
                        onTap: () => _deleteList(context, provider, list),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Item tile ─────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.black,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(
                item.checked ? Icons.circle : Icons.radio_button_unchecked,
                size: 22,
                color: item.checked ? Colors.black : Colors.black26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: 'FixelText',
                    fontSize: 16,
                    color: item.checked ? Colors.black38 : Colors.black,
                    decoration:
                        item.checked ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.black38,
                  ),
                ),
              ),
              if (item.quantity != null) ...[
                const SizedBox(width: 8),
                Text(
                  _quantityLabel(item),
                  style: const TextStyle(
                    fontFamily: 'FixelText',
                    fontSize: 14,
                    color: Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _quantityLabel(ShoppingItem item) {
    final q = item.quantity! % 1 == 0
        ? item.quantity!.toInt().toString()
        : item.quantity!.toString();
    if (item.unit.isNotEmpty) return '$q ${item.unit}';
    return q;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_outlined, size: 48, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            S.shoppingListEmptyTitle,
            style: TextStyle(
              fontFamily: 'FixelDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            S.shoppingListEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'FixelText',
              fontSize: 14,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
