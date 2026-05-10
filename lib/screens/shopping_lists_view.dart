import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/shopping_list.dart';
import '../providers/app_provider.dart';
import 'add_edit_shopping_list_screen.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsView extends StatelessWidget {
  const ShoppingListsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lists = context.watch<AppProvider>().shoppingLists;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(S.shoppingTitle,
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                S.shoppingListsCount(lists.length),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: lists.isEmpty
                    ? _EmptyState(onCreateTap: () => _createList(context))
                    : ListView.separated(
                        itemCount: lists.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _ShoppingListCard(list: lists[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          lists.isEmpty ? null : _BlackFab(onTap: () => _createList(context)),
    );
  }

  void _createList(BuildContext context) {
    HapticFeedback.mediumImpact();
    final existing = context.read<AppProvider>().shoppingLists.map((l) => l.name).toSet();
    final baseName = ShoppingList.defaultName(DateTime.now());
    var name = baseName;
    var counter = 1;
    while (existing.contains(name)) {
      name = '$baseName ($counter)';
      counter++;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddEditShoppingListScreen(initialName: name),
    ));
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            S.shoppingEmptyTitle,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.shoppingEmptySubtitle,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 14,
              color: Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onCreateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                S.shoppingEmptyBtn,
                style: const TextStyle(
                  fontFamily: 'FixelText',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── List card ─────────────────────────────────────────────────────────────────

class _ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  const _ShoppingListCard({required this.list});

  @override
  Widget build(BuildContext context) {
    final total = list.items.length;
    final done = list.checkedCount;

    return Dismissible(
      key: Key(list.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        context.read<AppProvider>().deleteShoppingList(list.id);
      },
      confirmDismiss: (_) => _confirmDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ShoppingListDetailScreen(listId: list.id),
        )),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        done == 0
                            ? S.shoppingItemsCount(total)
                            : S.shoppingCheckedOf(done, total),
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 12),
                Icon(
                  done == total ? Icons.circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: done == total ? Colors.black : Colors.black26,
                ),
              ],
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    await Future.microtask(() {});
    if (!context.mounted) return false;
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
    return result ?? false;
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _BlackFab extends StatelessWidget {
  final VoidCallback onTap;
  const _BlackFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
