import 'package:flutter_test/flutter_test.dart';
import 'package:listy_zakupow/shopping_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ShoppingState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    state = ShoppingState();
    await state.load();
    state.addStore('Test');
    state.addItem('A', '');
    state.addItem('B', '2 szt');
    state.addItem('C', '');
  });

  test('odznaczony produkt trafia na koniec listy', () async {
    final a = state.activeStore.items[0];
    final c = state.activeStore.items[2];
    state.toggle(a.id);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    state.toggle(c.id);

    expect(state.openItems.map((i) => i.name), ['B']);
    expect(state.doneItems.map((i) => i.name), ['A', 'C']);
  });

  test('zmiana kolejności przeciąganiem i strzałkami', () {
    state.moveItem(0, 3); // A na koniec
    expect(state.activeStore.items.map((i) => i.name), ['B', 'C', 'A']);
    state.moveBy(state.activeStore.items[2].id, -1);
    expect(state.activeStore.items.map((i) => i.name), ['B', 'A', 'C']);
  });

  test('cofnięcie usunięcia przywraca pozycję', () {
    final undo = state.removeItem(state.activeStore.items[1].id);
    expect(state.activeStore.items.map((i) => i.name), ['A', 'C']);
    undo();
    expect(state.activeStore.items.map((i) => i.name), ['A', 'B', 'C']);
  });

  test('lista zapisuje się i wczytuje ponownie', () async {
    final again = ShoppingState();
    await again.load();
    expect(again.stores.last.name, 'Test');
    expect(again.stores.last.items.length, 3);
  });
}
