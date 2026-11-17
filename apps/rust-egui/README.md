# Files — Rust + egui / eframe 0.37

Immediate-mode Rust GUI: the whole UI is rebuilt every frame from state.
Rendered with eframe's `glow` (OpenGL) backend.

```bash
cargo run --release -p fm-egui      # from the repository root
cargo test -p fm-egui
```

## Layout

```
src/
├── main.rs              composition root: adapters → use cases → eframe::run_native
├── app.rs               eframe::App — poll view model → build views → apply intents
├── theme.rs             tokens → egui Visuals/Style, font installation, icon tones
└── browser/
    ├── intent.rs        Intent — every user action as data
    ├── view_model.rs    BrowserViewModel — state, apply(), poll(); no egui types
    └── view/            immediate-mode views: (&mut Ui, &BrowserViewModel) → intents
        ├── mod.rs           panel layout
        ├── shortcuts.rs     global keys (consumed, so widgets don't also react)
        ├── toolbar.rs, sidebar.rs, file_table.rs (egui_extras::TableBuilder), status_bar.rs
```

## Notes

* **Immediate-mode MVVM:** views take the view model by shared reference, so
  they physically can't mutate it, and return `Intent`s instead. The app applies
  them after the frame.
* Loads run on a `std::thread` and report back over an `mpsc` channel. The
  view model gets a generic *waker* closure (it calls `ctx.request_repaint()`),
  which keeps egui out of the view model.
* egui only repaints on input or `request_repaint`, so the app idles at ~0% CPU.
