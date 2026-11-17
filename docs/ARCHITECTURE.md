# Architecture

All six apps implement the **same feature set on the same architecture**, so that
differences you notice come from the toolkit, not from the design.

## Feature scope (first draft)

| Feature | Details |
|---|---|
| List a directory | Name, size, modified date, kind; Nerd Font icon per type |
| Navigate | Double-click / <kbd>Enter</kbd> on a folder or a link to a folder |
| History | Back / Forward / Up, with buttons and shortcuts |
| Breadcrumbs | Every path segment is clickable |
| Places sidebar | Home + XDG user dirs (Desktop, Documents…) + File System (`/`) |
| Hidden files | Toggle with the eye button or <kbd>Ctrl</kbd>+<kbd>H</kbd> (hidden by default) |
| Keyboard selection | <kbd>↑</kbd>/<kbd>↓</kbd> move the selection and scroll it into view |
| Errors | Unreadable folders show a dismissible banner; your location stays the same |
| Status bar | Folder/file counts, total size, hidden count, current path / loading state |

Shortcuts: <kbd>Alt</kbd>+<kbd>←</kbd> back, <kbd>Alt</kbd>+<kbd>→</kbd> forward,
<kbd>Alt</kbd>+<kbd>↑</kbd> or <kbd>Backspace</kbd> up, <kbd>F5</kbd> refresh,
<kbd>Esc</kbd> dismiss error.

Opening files, file operations, search and sorting are out of scope for this draft.

## Layers (hexagonal / ports & adapters + DDD)

```
┌──────────────────────────────────────────────────────────────┐
│ Composition root (main)  – builds adapters, injects use cases │
├──────────────────────────────────────────────────────────────┤
│ Presentation  – toolkit-specific                              │
│   theme (tokens) · view model · views · keyboard · formatting │
├──────────────────────────────────────────────────────────────┤
│ Application   – use cases: BrowseDirectory, ListPlaces        │
├──────────────────────────────────────────────────────────────┤
│ Domain        – pure, no I/O                                  │
│   DirectoryPath (VO) · FileEntry (entity) · DirectoryListing  │
│   (aggregate) · NavigationHistory (aggregate root) · Place    │
│   FsError · ports: FileSystemRepository, PlacesProvider       │
├──────────────────────────────────────────────────────────────┤
│ Infrastructure – adapters for the ports                       │
│   LocalFileSystem (std fs / dart:io / std::filesystem / Io)   │
│   XdgPlaces (XDG user-dirs with ~/Name fallbacks)             │
└──────────────────────────────────────────────────────────────┘
          dependencies point inwards only (→ domain)
```

Where the language allows it, **the build enforces the boundaries**:

* **Rust**: `fm-core` (domain/application/infrastructure) and `fm-ui-kit` are
  separate crates in a Cargo workspace. They have no GUI dependency, and all
  three Rust front-ends reuse them, so only the presentation layer differs.
* **C++**: each layer is its own CMake library target (`fm_domain`,
  `fm_application`, `fm_infrastructure`, `fm_presentation`). Only the
  executable links infrastructure, and only presentation links Dear ImGui.
* **Zig**: the core is its own module (`src/core.zig`) without imports of
  raylib or Clay, so it physically can't reach the UI.
* **Dart**: follows the official [Flutter app architecture guide](https://docs.flutter.dev/app-architecture):
  `ui/` (views + view models), `domain/` (models + use cases), `data/`
  (repositories + services), `config/` (DI), `utils/` (Result).

### Key domain rules (identical in every app)

* `DirectoryPath` can only be created from an **absolute** path.
* `DirectoryListing` always holds entries in **browse order**: folders first,
  then case-insensitive name.
* Dot-files are **hidden**. Visibility is a filter on the listing and never
  triggers a reload.
* `NavigationHistory` is **two-phase**. The view model *peeks* a destination,
  loads it in the background, and *commits* `visit` / `goBack` / `goForward`
  only if the load succeeds. A failed load never corrupts history.
* Every load carries a **ticket**, and responses from superseded navigations
  are dropped. Double-clicking through folders quickly never shows stale
  content.

## MVVM across retained-mode, declarative and immediate-mode toolkits

"MVVM" looks different depending on the toolkit's paradigm. Each app uses the
form that is idiomatic for its toolkit:

| App | Paradigm | How MVVM is expressed |
|---|---|---|
| Flutter | Declarative, retained widget tree | `BrowserViewModel extends ChangeNotifier`, created by `ChangeNotifierProvider`; views rebuild through `ListenableBuilder`; keys go through `Shortcuts` → `Intent` → `Actions`; failures use a sealed `Result` type. |
| Slint | Declarative markup compiled to Rust | The `BrowserViewModel` **Slint global** is the binding surface: `in` properties for state, callbacks for commands. A Rust `BrowserViewModel` owns the state, *presents* it into the global (through a pure `presenter` module) and implements the callbacks. This is the closest to textbook MVVM. |
| iced | The Elm Architecture (MVU) | The state struct *is* the view model, `Message` lists every intent, `update` is the only code that mutates state (and returns `Task`s for async work), and `view` is a pure function. Forcing two-way bindings onto iced would fight the framework, so it uses MVU. |
| egui | Immediate mode | Views are functions `(&mut Ui, &BrowserViewModel) → Vec<Intent>`: they **cannot** mutate state. The app applies intents after the frame. Async results arrive over a channel, and a waker callback (no egui types in the view model) triggers a repaint. |
| Dear ImGui | Immediate mode | Same unidirectional shape: views get a `const BrowserViewModel&` and append `Action`s (a `std::variant`), and `dispatch()` applies them after the frame. `DirectoryLoader` runs the use case on a worker thread. |
| Zig + Clay | Immediate-mode layout | Views get `*const BrowserViewModel` plus a `Frame` (frame arena, input snapshot, intent sink). Intents are applied after rendering, because Clay keeps string pointers until the frame has been drawn. |

## Visual language

`design/tokens.json` is the single source of truth. Each app mirrors it in
its own theme module (`theme.rs`, `app_colors.dart` + `AppPalette` extension,
`Palette.hpp`, `theme.slint`, `theme.zig`).

* **Aqua** `#00E5E0`: primary. Folder icons, selection outline, focus, enabled tool buttons, the active toggle.
* **Purple** `#A06CFF`: interactive accent. Hover fill (`#3C2A66`), the active place, breadcrumb chevrons, symlinks, tooltips.
* **Gold** `#FFC94D`: highlight. App title, column headers, current breadcrumb, status-bar figures, media files.
* Dark teal surfaces (`#0B1A20` → `#16323C`) keep the accents readable.
* **Elevation**: file list (flat) < column header < toolbar < places sidebar.
  Higher sections are lighter and cast shadows onto lower ones; tool buttons
  are raised with a small shadow and sit flat when pressed or disabled. See
  [ELEVATION.md](ELEVATION.md).

**Font:** 0xProto Nerd Font (`assets/fonts`). It was built from the official
[0xProto](https://github.com/0xType/0xProto) release with the official Nerd
Fonts `font-patcher --complete`. Icons are Nerd Font glyphs, so no icon assets
are needed. Dear ImGui and raylib size fonts by line height, unlike the others,
which use em size. Those two convert with the font's metrics (×1.56) so all
apps render at the same visual size.
