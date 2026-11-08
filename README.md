# Listy zakupów — PWA we Flutterze

Listy zakupów do poszczególnych sklepów, każdy sklep w osobnej zakładce.

- **Zakładki sklepów:** przycisk „+” dodaje sklep, a licznik przy nazwie pokazuje, ile produktów zostało do kupienia.
- **Tryb Edycja:** dodawanie produktów (nazwa i ilość), zmiana kolejności przez przeciąganie za uchwyt ⠿ lub strzałkami, poprawianie produktu po stuknięciu, usuwanie z opcją „Cofnij”, zmiana nazwy i usuwanie sklepu.
- **Tryb Zakupy:** stuknięcie odznacza produkt. Odznaczone trafiają na koniec listy pod nagłówek „Kupione” i są przyciemnione oraz przekreślone. Ponowne stuknięcie przywraca produkt. Na górze widać pasek postępu, a na dole jest przycisk „Usuń kupione z listy”.
- Dane zapisują się w telefonie (localStorage przeglądarki) przy każdej zmianie, więc nie trzeba konta ani serwera.
- Jasny i ciemny motyw zmieniają się automatycznie, a interfejs jest po polsku.

## Uruchomienie lokalnie

Wymagany Flutter 3.24 lub nowszy (`flutter --version`).

```bash
flutter pub get
flutter run -d chrome          # podgląd w przeglądarce
flutter test                   # testy logiki listy
flutter build web --release    # gotowa PWA w build/web
```

Zawartość `build/web` można wrzucić na dowolny hosting statyczny (GitHub Pages, Netlify, Firebase Hosting, Cloudflare Pages). PWA wymaga HTTPS.

## Publikacja na GitHub Pages (automatycznie)

1. Utwórz repozytorium na GitHubie i wypchnij do niego ten folder (gałąź `main`).
2. W repozytorium wejdź w **Settings → Pages → Build and deployment → Source** i wybierz **GitHub Actions**.
3. Każdy push na `main` uruchomi `.github/workflows/deploy.yml`, który sprawdzi kod, przepuści testy, zbuduje aplikację i ją opublikuje.
   Adres to `https://<twoj-login>.github.io/<nazwa-repo>/`.

## Instalacja na telefonie

- **Android (Chrome):** otwórz adres, wybierz menu ⋮ i „Dodaj do ekranu głównego” / „Zainstaluj aplikację”.
- **iPhone (Safari):** otwórz adres, wybierz Udostępnij i „Do ekranu początkowego”.

## Struktura

```
lib/
  main.dart            motyw (Material 3, kolor #2E6A4F), polska lokalizacja
  models.dart          Store, ShopItem (+ JSON)
  shopping_state.dart  stan i logika (ChangeNotifier) + zapis shared_preferences
  home_page.dart       ekran: zakładki, tryb Zakupy, tryb Edycja, dialogi
web/                   index.html, manifest.json, ikony PWA
test/                  testy logiki (kolejność, odznaczanie, cofanie, zapis)
```

Przy pierwszym uruchomieniu aplikacja tworzy przykładowe sklepy Lidl, Biedronka i Rossmann. Możesz je zmienić w trybie Edycja albo podmienić w `_starterStores()` w `lib/shopping_state.dart`.
