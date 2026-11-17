# Files — Zig 0.17 + Clay (raylib renderer)

[Clay](https://github.com/nicbarker/clay) is an immediate-mode **layout** engine.
The app declares the UI each frame, Clay computes the layout and emits render
commands, and raylib draws them. The app uses the idiomatic Zig bindings
[`zclay`](https://github.com/johan0A/clay-zig-bindings) (bundling Clay v0.14 and
a raylib renderer) and [`raylib-zig`](https://github.com/raylib-zig/raylib-zig).

```bash
cd apps/zig-clay
zig build run                      # debug
zig build -Doptimize=ReleaseSafe   # optimised
zig build test
```

Requires **Zig 0.17.1**. Dependencies are declared in `build.zig.zon` and
fetched automatically on the first build. Zig 0.17 stores them in a local
`zig-pkg/` folder, which is gitignored.

## Layout

```
src/
├── core.zig                    core module root (no UI imports)
├── domain/                     DirectoryPath, FileEntry, DirectoryListing, NavigationHistory,
│                               Place, fs_error, ports (vtable interfaces, like std.mem.Allocator)
├── application/                BrowseDirectory, ListPlaces
├── infrastructure/             LocalFileSystem (std.Io.Dir), XdgPlaces
├── presentation/
│   ├── BrowserViewModel.zig    state, apply(intent), tick(); background loads on std.Thread
│   ├── Intent.zig, Frame.zig   intents; per-frame arena + input snapshot + intent sink
│   ├── theme.zig, glyphs.zig, format.zig
│   └── view/                   root, toolbar, sidebar, file_list, status_bar, widgets (Clay)
├── platform/RaylibHost.zig     window, fonts, input sampling, Clay ⇄ raylib frame
└── main.zig                    composition root (`pub fn main(init: std.process.Init)`)
```

## Notes

* Idiomatic Zig: file-as-struct modules, explicit allocators everywhere (arena
  per listing, arena per frame), error sets, vtable-based ports, `test` blocks
  next to the code, and the core as a separate build module so it can't
  import the UI.
* **Pitfall worth knowing:** never `return` (or `try`) out of a Clay
  `cl.UI()(...)({ ... })` block. The element would never be closed and the
  layout tree gets corrupted.
* Clay keeps pointers to text until rendering, so formatted strings live in a
  per-frame arena, and intents are applied only after the frame is drawn.
* The file list is virtualised manually (spacer elements around the visible
  window) to stay within Clay's element budget on huge folders.
* Clay/raylib have no text input, tooltip or double-click widgets: the app
  implements tooltips (floating elements), double-click detection and hover
  cursors itself. Keys are read from raylib's key queue so fast presses are
  never dropped.
* Dates are shown in **UTC**, because Zig's standard library has no time-zone
  database.
* raylib bakes a fixed glyph set into its atlas (ASCII, Latin-1 and the icon
  codepoints in `glyphs.zig`). Characters outside it, e.g. CJK file names,
  render as `?`. That's a real limitation of this stack compared to the
  others.
