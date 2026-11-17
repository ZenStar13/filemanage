# Files — Dart + Flutter (Linux desktop)

Flutter with Dart 3.14. Structure follows the official
[Flutter app architecture guide](https://docs.flutter.dev/app-architecture)
(MVVM: Views, ViewModels, Repositories, Services).

```bash
cd apps/dart-flutter
flutter pub get
flutter run -d linux              # or: flutter build linux --release
flutter analyze && flutter test
```

Linux build prerequisites: `clang cmake ninja-build pkg-config libgtk-3-dev`.

## Layout

```
lib/
├── main.dart                         runApp + MultiProvider (composition root)
├── config/dependencies.dart          provider graph: services → repositories → use cases
├── domain/
│   ├── models/                       DirectoryPath, FileEntry, DirectoryListing, Place, FsFailure
│   ├── navigation/                   NavigationHistory (aggregate), NavigationRequest (sealed)
│   └── use_cases/                    BrowseDirectoryUseCase
├── data/
│   ├── services/                     FileSystemService (dart:io), PlacesService (XDG)
│   └── repositories/                 abstract interfaces + local/XDG implementations
├── ui/
│   ├── core/theme/                   AppColors, AppPalette (ThemeExtension), AppTheme, AppGlyphs, Dimens
│   ├── core/formatters.dart, core/widgets/glyph.dart
│   └── browser/
│       ├── view_models/              BrowserViewModel (ChangeNotifier)
│       └── widgets/                  BrowserScreen, toolbar, breadcrumbs, sidebar, file list/row…
└── utils/result.dart                 sealed Result<T> (Ok / Error)
test/                                 domain tests, view-model tests with fakes, widget test
```

## Notes

* Material lives in the decoupled `material_ui` package in this Flutter
  version, so widgets import `package:material_ui/material_ui.dart`. The view
  model only imports `flutter/foundation.dart`.
* Extra semantic colours (hover, selection, highlight…) are a `ThemeExtension`
  (`context.palette`) rather than hard-coded values.
* Keyboard handling uses `Shortcuts` → `Intent` → `Actions` instead of raw key
  listeners.
* Hover is ephemeral UI state, so it lives in `FileRow`'s `State`, not in
  the view model, as the guide recommends.
* `assets/fonts` is a symlink to the repository's shared font folder.
* The view model uses a ticket rather than the guide's `Command` helper,
  because `Command` ignores new calls while one is running. A file manager
  needs "latest navigation wins" (e.g. leaving a slow network mount).
