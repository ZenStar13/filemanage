# Files — Rust + Slint 1.19

Declarative UI written in the `.slint` language, compiled to Rust at build time
(`build.rs`). The font is embedded by the compiler.

```bash
cargo run --release -p fm-slint     # from the repository root
cargo test -p fm-slint
```

## Layout

```
ui/                                  ← the View (declarative)
├── app.slint                        root window, key bindings (FocusScope), overlay
├── view-model.slint                 global BrowserViewModel: `in` state + callbacks
├── theme.slint                      Palette / Typography / Metrics / Glyphs globals + font import
└── components/
    ├── toolbar.slint, sidebar.slint, file-list.slint (virtualised ListView), status-bar.slint
    ├── icon-button.slint            glyph button publishing to the tooltip service
    └── tooltip.slint                TooltipService global + window-level overlay
src/                                 ← the ViewModel (Rust)
├── main.rs                          composition root
└── browser/
    ├── view_model.rs                BrowserViewModel: owns State, wires callbacks, presents
    └── presenter.rs                 pure domain → Slint struct mapping (unit-tested)
```

## Notes

* **Textbook MVVM:** `view-model.slint` declares the contract. Rust writes
  properties and implements callbacks, and the `.slint` files only bind to it.
* Rows live in a single `VecModel` handed to Slint once. Selection changes
  update just the two affected rows (`set_row_data`).
* Loads run on a worker thread. The result is awaited on the UI thread with
  `slint::spawn_local` plus a oneshot channel, so the `Rc` view model never
  crosses threads.
* Tooltips use a window-level overlay driven by a `TooltipService` global,
  because Slint's `z` only orders siblings. Nerd Font glyphs are wider than
  their advance width and Slint clips `Text` to its geometry, so icon texts
  fill their parent.
* The workspace lint is `unsafe_code = "deny"` rather than `forbid`, because
  Slint-generated code locally re-allows it. Generated code lives in its own
  `ui` module with its own lint allowances.
