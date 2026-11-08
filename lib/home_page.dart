import 'package:flutter/material.dart';

import 'models.dart';
import 'shopping_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state});

  final ShoppingState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (!state.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final store = state.activeStore;
        final isShop = state.mode == ListMode.shop;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Zakupy'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SegmentedButton<ListMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ListMode.shop,
                      icon: Icon(Icons.shopping_cart_outlined),
                      label: Text('Zakupy'),
                    ),
                    ButtonSegment(
                      value: ListMode.edit,
                      icon: Icon(Icons.edit_outlined),
                      label: Text('Edycja'),
                    ),
                  ],
                  selected: {state.mode},
                  onSelectionChanged: (s) => state.setMode(s.first),
                ),
              ),
            ],
            bottom: StoreTabs(state: state),
          ),
          body: SafeArea(
            top: false,
            child: isShop
                ? ShopView(state: state, store: store)
                : EditView(key: ValueKey(store.id), state: state, store: store),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------ zakładki

class StoreTabs extends StatelessWidget implements PreferredSizeWidget {
  const StoreTabs({super.key, required this.state});

  final ShoppingState state;

  @override
  Size get preferredSize => const Size.fromHeight(49);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 49,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 6),
              itemCount: state.stores.length,
              itemBuilder: (context, i) => _StoreTab(
                store: state.stores[i],
                active: i == state.activeIndex,
                onTap: () => state.selectStore(i),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dodaj sklep',
            icon: const Icon(Icons.add),
            onPressed: () => _addStore(context),
          ),
        ],
      ),
    );
  }

  Future<void> _addStore(BuildContext context) async {
    final name = await showTextDialog(
      context,
      title: 'Nowy sklep',
      label: 'Nazwa sklepu',
      confirm: 'Dodaj',
    );
    if (name != null && name.trim().isNotEmpty) state.addStore(name.trim());
  }
}

class _StoreTab extends StatelessWidget {
  const _StoreTab({
    required this.store,
    required this.active,
    required this.onTap,
  });

  final Store store;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? scheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.name.isEmpty ? 'Bez nazwy' : store.name,
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${store.remaining}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ tryb zakupów

class ShopView extends StatelessWidget {
  const ShopView({super.key, required this.state, required this.store});

  final ShoppingState state;
  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = state.openItems;
    final done = state.doneItems;
    final total = store.items.length;
    final progress = total == 0 ? 0.0 : done.length / total;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('W koszyku ${done.length} z $total',
                      style: theme.textTheme.bodyMedium),
                  Text('${(progress * 100).round()}%',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
        Expanded(
          child: total == 0
              ? EmptyState(
                  hint: 'Przełącz na Edycję, aby dodać produkty.',
                  action: FilledButton.tonalIcon(
                    onPressed: () => state.setMode(ListMode.edit),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edytuj listę'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    for (final item in open)
                      _ShopTile(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => state.toggle(item.id),
                      ),
                    if (done.isNotEmpty)
                      _SectionHeader(text: 'Kupione · ${done.length}'),
                    for (final item in done)
                      _ShopTile(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => state.toggle(item.id),
                      ),
                  ],
                ),
        ),
        if (done.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () {
                final undo = state.clearDone();
                showUndo(context, 'Usunięto kupione produkty', undo);
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text('Usuń kupione z listy (${done.length})'),
            ),
          ),
      ],
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({super.key, required this.item, required this.onTap});

  final ShopItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = item.done;
    final strike = done ? TextDecoration.lineThrough : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedOpacity(
        opacity: done ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: done
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(
                  children: [
                    Checkbox(value: done, onChanged: (_) => onTap()),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(decoration: strike),
                      ),
                    ),
                    if (item.qty.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: done
                              ? Colors.transparent
                              : scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.qty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: done
                                ? scheme.onSurfaceVariant
                                : scheme.onSecondaryContainer,
                            decoration: strike,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
      child: Row(
        children: [
          Text(text,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- tryb edycji

class EditView extends StatefulWidget {
  const EditView({super.key, required this.state, required this.store});

  final ShoppingState state;
  final Store store;

  @override
  State<EditView> createState() => _EditViewState();
}

class _EditViewState extends State<EditView> {
  late final TextEditingController _storeName =
      TextEditingController(text: widget.store.name);
  final _name = TextEditingController();
  final _qty = TextEditingController();
  final _nameFocus = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _storeName.dispose();
    _name.dispose();
    _qty.dispose();
    _nameFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    widget.state.addItem(name, _qty.text.trim());
    _name.clear();
    _qty.clear();
    _nameFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteStore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć sklep?'),
        content: Text(
            'Sklep „${widget.store.name}” i jego lista zostaną usunięte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true) widget.state.deleteActiveStore();
  }

  Future<void> _editItem(ShopItem item) async {
    final result = await showItemDialog(context, item);
    if (result != null && result.$1.isNotEmpty) {
      widget.state.updateItem(item.id, result.$1, result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final items = widget.store.items;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _storeName,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nazwa sklepu'),
                  onChanged: state.renameActiveStore,
                ),
              ),
              IconButton(
                tooltip: 'Usuń ten sklep',
                color: theme.colorScheme.error,
                onPressed: state.canDeleteStore ? _deleteStore : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'Przeciągnij za uchwyt lub użyj strzałek, aby zmienić kolejność. '
            'Stuknij produkt, aby go poprawić.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(hint: 'Dodaj pierwszy produkt poniżej.')
              : ReorderableListView.builder(
                  scrollController: _scroll,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: items.length,
                  onReorder: state.moveItem,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return _EditTile(
                      key: ValueKey(item.id),
                      item: item,
                      index: i,
                      isFirst: i == 0,
                      isLast: i == items.length - 1,
                      onUp: () => state.moveBy(item.id, -1),
                      onDown: () => state.moveBy(item.id, 1),
                      onEdit: () => _editItem(item),
                      onDelete: () {
                        final undo = state.removeItem(item.id);
                        showUndo(context, 'Usunięto „${item.name}”', undo);
                      },
                    );
                  },
                ),
        ),
        Material(
          color: theme.colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Produkt',
                      hintText: 'np. Ser żółty',
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _qty,
                    decoration: const InputDecoration(
                      labelText: 'Ilość',
                      hintText: '2 szt',
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Dodaj produkt',
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditTile extends StatelessWidget {
  const _EditTile({
    super.key,
    required this.item,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopItem item;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strike = item.done ? TextDecoration.lineThrough : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: item.done ? 0.55 : 1,
        child: Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                      child: Icon(Icons.drag_indicator,
                          color: scheme.outline, semanticLabel: 'Przeciągnij'),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.name,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(decoration: strike)),
                          if (item.qty.isNotEmpty)
                            Text(item.qty,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Przesuń w górę',
                  onPressed: isFirst ? null : onUp,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: 'Przesuń w dół',
                  onPressed: isLast ? null : onDown,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                IconButton(
                  tooltip: 'Usuń produkt',
                  color: scheme.error,
                  onPressed: onDelete,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ wspólne

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.hint, this.action});

  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 44, color: theme.colorScheme.outline),
            const SizedBox(height: 10),
            Text('Lista jest pusta', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

void showUndo(BuildContext context, String message, VoidCallback undo) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Cofnij', onPressed: undo),
      ),
    );
}

Future<String?> showTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(confirm),
        ),
      ],
    ),
  );
}

/// Zwraca (nazwa, ilość) albo null po anulowaniu.
Future<(String, String)?> showItemDialog(BuildContext context, ShopItem item) {
  final name = TextEditingController(text: item.name);
  final qty = TextEditingController(text: item.qty);
  (String, String) result() => (name.text.trim(), qty.text.trim());
  return showDialog<(String, String)>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Popraw produkt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Produkt'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qty,
            decoration: const InputDecoration(labelText: 'Ilość'),
            onSubmitted: (_) => Navigator.pop(ctx, result()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, result()),
          child: const Text('Zapisz'),
        ),
      ],
    ),
  );
}
