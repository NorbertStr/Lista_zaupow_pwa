/// Produkt na liście zakupów.
class ShopItem {
  ShopItem({
    required this.id,
    required this.name,
    this.qty = '',
    this.done = false,
    this.doneAt = 0,
  });

  final String id;
  String name;

  /// Ilość jako wolny tekst, np. „3 szt”, „500 g”.
  String qty;

  /// Czy produkt jest już w koszyku (odznaczony).
  bool done;

  /// Kiedy odznaczono — kupione układają się w kolejności odhaczania.
  int doneAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'done': done,
        'doneAt': doneAt,
      };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        qty: json['qty'] as String? ?? '',
        done: json['done'] as bool? ?? false,
        doneAt: (json['doneAt'] as num?)?.toInt() ?? 0,
      );
}

/// Sklep z własną listą zakupów (jedna zakładka).
class Store {
  Store({required this.id, required this.name, List<ShopItem>? items})
      : items = items ?? <ShopItem>[];

  final String id;
  String name;

  /// Kolejność ustalona w trybie edycji.
  final List<ShopItem> items;

  int get remaining => items.where((i) => !i.done).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
