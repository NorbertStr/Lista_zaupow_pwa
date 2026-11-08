import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

enum ListMode { shop, edit }

/// Cały stan aplikacji. Każda zmiana jest od razu zapisywana lokalnie
/// (w PWA: localStorage przeglądarki), więc listy działają offline.
class ShoppingState extends ChangeNotifier {
  static const _storageKey = 'shopping_lists_v1';

  final List<Store> stores = [];
  ListMode mode = ListMode.shop;
  bool loaded = false;

  int _active = 0;
  int _seq = 0;
  SharedPreferences? _prefs;

  int get activeIndex =>
      stores.isEmpty ? 0 : math.max(0, math.min(_active, stores.length - 1));

  Store get activeStore => stores[activeIndex];

  /// Produkty do kupienia — w kolejności z trybu edycji.
  List<ShopItem> get openItems =>
      activeStore.items.where((i) => !i.done).toList();

  /// Odznaczone produkty — na końcu listy, w kolejności odhaczania.
  List<ShopItem> get doneItems =>
      activeStore.items.where((i) => i.done).toList()
        ..sort((a, b) => a.doneAt.compareTo(b.doneAt));

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  // ---------------------------------------------------------------- zapis

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        stores.addAll((data['stores'] as List<dynamic>).map(
            (e) => Store.fromJson(Map<String, dynamic>.from(e as Map))));
        _active = (data['active'] as num?)?.toInt() ?? 0;
      } catch (_) {
        stores.clear();
      }
    }
    if (stores.isEmpty) stores.addAll(_starterStores());
    loaded = true;
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    _prefs?.setString(
      _storageKey,
      jsonEncode({
        'active': _active,
        'stores': stores.map((s) => s.toJson()).toList(),
      }),
    );
  }

  List<Store> _starterStores() => [
        Store(id: _newId(), name: 'Lidl', items: [
          ShopItem(id: _newId(), name: 'Marchewka', qty: '3 szt'),
          ShopItem(id: _newId(), name: 'Mleko', qty: '2 l'),
          ShopItem(id: _newId(), name: 'Chleb żytni', qty: '1 szt'),
        ]),
        Store(id: _newId(), name: 'Biedronka'),
        Store(id: _newId(), name: 'Rossmann'),
      ];

  // --------------------------------------------------------------- sklepy

  void setMode(ListMode value) {
    mode = value;
    notifyListeners();
  }

  void selectStore(int index) {
    _active = index;
    _changed();
  }

  void addStore(String name) {
    stores.add(Store(id: _newId(), name: name));
    _active = stores.length - 1;
    mode = ListMode.edit;
    _changed();
  }

  void renameActiveStore(String name) {
    activeStore.name = name;
    _changed();
  }

  bool get canDeleteStore => stores.length > 1;

  void deleteActiveStore() {
    if (!canDeleteStore) return;
    final index = activeIndex;
    stores.removeAt(index);
    _active = math.max(0, index - 1);
    _changed();
  }

  // ------------------------------------------------------------- produkty

  void addItem(String name, String qty) {
    activeStore.items.add(ShopItem(id: _newId(), name: name, qty: qty));
    _changed();
  }

  void updateItem(String id, String name, String qty) {
    final item = activeStore.items.firstWhere((i) => i.id == id);
    item
      ..name = name
      ..qty = qty;
    _changed();
  }

  /// Odznacza / przywraca produkt.
  void toggle(String id) {
    final item = activeStore.items.firstWhere((i) => i.id == id);
    item.done = !item.done;
    item.doneAt = item.done ? DateTime.now().millisecondsSinceEpoch : 0;
    _changed();
  }

  /// Dla ReorderableListView.onReorder.
  void moveItem(int oldIndex, int newIndex) {
    final items = activeStore.items;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    _changed();
  }

  /// Przesunięcie strzałkami o [delta] pozycji.
  void moveBy(String id, int delta) {
    final items = activeStore.items;
    final from = items.indexWhere((i) => i.id == id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= items.length) return;
    items.insert(to, items.removeAt(from));
    _changed();
  }

  /// Usuwa produkt; zwraca funkcję cofającą.
  VoidCallback removeItem(String id) => _removeWhere((i) => i.id == id);

  /// Usuwa wszystkie kupione; zwraca funkcję cofającą.
  VoidCallback clearDone() => _removeWhere((i) => i.done);

  VoidCallback _removeWhere(bool Function(ShopItem) test) {
    final store = activeStore;
    final removed = <MapEntry<int, ShopItem>>[];
    for (var i = 0; i < store.items.length; i++) {
      if (test(store.items[i])) removed.add(MapEntry(i, store.items[i]));
    }
    store.items.removeWhere(test);
    _changed();
    return () {
      for (final e in removed) {
        store.items.insert(math.min(e.key, store.items.length), e.value);
      }
      _changed();
    };
  }
}
