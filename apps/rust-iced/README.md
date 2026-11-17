# Files — Rust + iced 0.14

Native Rust GUI built on **The Elm Architecture** (Model → Message → Update → View),
rendered by wgpu, with a tiny-skia CPU fallback.

```bash
cargo run --release -p fm-iced      # from the repository root
cargo test -p fm-iced
```

## Layout

```
src/
├── main.rs              composition root: adapters → use cases → iced::application(...)
├── app.rs               App shell (routes messages to features; title/theme/subscription)
├── theme/
│   ├── mod.rs           design tokens → iced Palette / custom Theme, fonts
│   └── style.rs         per-widget style functions (rows, buttons, breadcrumbs…)
└── browser/             the browser feature
    ├── state.rs         Browser — the model / view model (plain data)
    ├── message.rs       Message, Navigation, LoadOutcome — every intent
    ├── update.rs        the only code that mutates state; returns Task for async I/O
    ├── keyboard.rs      key events → messages (pure, unit-tested)
    └── view/            pure `&Browser → Element<Message>` functions
        ├── mod.rs, toolbar.rs, sidebar.rs, file_list.rs, status_bar.rs
```

Domain, use cases and filesystem adapters come from the shared `fm-core` crate.
Tokens, glyphs and formatters come from `fm-ui-kit`.

## Notes

* Directory reads run through `Task::perform` on iced's thread pool, so the UI
  never blocks. Each `LoadOutcome` carries a ticket so stale results are dropped.
* `update` returns `Task<Message>`, which makes the update logic testable
  without a window: see the tests in `browser/update.rs`.
* Hover is tracked in state (`mouse_area` enter/exit messages). This is the
  idiomatic way to style hover on a non-button widget in iced.
