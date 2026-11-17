# Elevation & depth: what it took in each stack

This is the first "visual layer" change applied to all six apps. It shows what
adding depth costs in each toolkit, both in code and in rendering.

## The change

| Section | Elevation | Surface | Shadow (x, y, blur, black α) |
|---|---|---|---|
| File list | 0 (flat) | `#0B1A20` | none |
| Column header | 1 | `#10262E` | 0, 1, 4, 0.35, cast down |
| Toolbar | 2 | `#132C35` | 0, 2, 8, 0.45, cast down |
| Places sidebar | 3 (highest) | `#17323C` | 3, 0, 14, 0.55, cast right |
| Tool buttons | on the toolbar | `#1D3D49` | 0, 1, 3, 0.45; flat when pressed or disabled |

Higher sections are both **lighter** (tonal elevation, which carries most of the
effect on a dark theme) and **cast a shadow onto the sections below**. That
second part is the hard bit: the shadow must be painted *over* neighbouring
sections, so every toolkit needs some notion of z-order. Values live in
`design/tokens.json` → `elevation`.

Also fixed: **the hidden-files icon was off-centre**. Nerd Font icons are
drawn wider than their advance width, and the ink extends right of where
toolkits centre the glyph: 0.27 em for the eye-slash, about 4 px at 15 px. Each
toolbar glyph now has an optical-centre correction computed from the font's
`glyf`/`hmtx` tables (`design/tokens.json` → `glyphCentering`). Every toolbar
icon got slightly better, not just the eye.

## Per stack

| Stack | Shadows built in? | How z-order was solved | How the shadow is rendered | Code touched* |
|---|---|---|---|---|
| **Flutter** | ✅ `BoxShadow`, Material elevation | Flutter paints later children on top, so the sections became `Stack`s ordered by elevation | Engine (Skia/Impeller) analytic blur, on the GPU | +118 −38, +38 new (mostly the `Stack` restructure) |
| **iced** | ✅ `Shadow` on container and button styles | `stack!` draws each later child on a new layer | wgpu quad shader (analytic, GPU) | +74 −27 |
| **Slint** | ✅ `drop-shadow-*` properties | `z` works between siblings, even inside layouts | Renderer-native (femtovg/Skia) | +71 −12 (the smallest diff) |
| **egui** | ⚠️ `Shadow` on `Frame`s, but panels have no z-order | Shadows painted on a layer above the panels, clipped to the receiving region. Button shadows go into a paint slot reserved *before* the button | Tessellated blurred rect (CPU mesh, GPU raster) | +98 −25, +26 new |
| **Dear ImGui** | ❌ none in the main branch | A click-through overlay window above the root window but below tooltips. Button shadows use a draw-list channel *under* the button | Hand-written: gradient strips for edges, stacked translucent rounded rects for buttons | +102 −20, +97 new |
| **Zig + Clay** | ❌ none (Clay only does layout) | Floating `custom` elements with a z-index per elevation. Button shadows ride on the button's `user_data` | Hand-written in the raylib renderer pass: gradient strips + stacked rounded rects | +98 −10, +76 new |

\* App-specific lines. The three Rust apps also share +57 lines of tokens and
glyph offsets in `fm-ui-kit`.

### Notes and pitfalls found

- **Flutter**: the most idiomatic route also gives state-aware button
  shadows for free: `ButtonStyle.elevation` drops to 0 when disabled, and a
  `WidgetStateProperty` flattens it while pressed. The cost is restructuring
  layout into `Stack`s, because there's no z-index.
- **iced**: shadows are just a style field, but they only fall *onto*
  neighbours once those neighbours are on an earlier `stack!` layer.
  Otherwise, later siblings paint over them.
- **Slint**: closest to CSS. Earlier, `z` seemed not to help tooltips; that
  was a nested-element problem. Between siblings, including layout children,
  it works.
- **egui**: `Panel`s all paint on the background layer, so a frame's own
  `shadow` gets covered by the next panel. Painting shadows on an upper
  layer, clipped to the receiving area, works well. egui also drew panel
  separator lines that the elevation now replaces (`show_separator_line(false)`).
- **Dear ImGui**: there's no shadow primitive (an unmerged "shadows" branch
  exists upstream). Everything is drawn by hand. Watch the default
  `ItemSpacing` gaps between sections, which show up as hard dark bands.
- **Zig + Clay**: floating elements sized with `percent` resolve to roughly
  zero in Clay 0.14; use `grow`, which resolves against the attached parent.
  Clay also doesn't copy the z-index into `custom` render commands; the
  roots are still sorted correctly. The renderer needed a wrapper pass around
  zclay's stock raylib renderer.

### Rendering cost

<!-- ELEVATION-METRICS -->

GPU-backed toolkits (Flutter, iced, Slint/femtovg, egui) draw shadows in the
same pass as everything else, so a handful of them is essentially free. The
hand-drawn approaches (ImGui, Clay) issue a few extra quads per shadow: also
negligible at this scale, but each new effect (blur behind, coloured glow,
animation) is more code to write. Effects that need the pixels *behind* a
surface, such as blurred translucency, aren't available in iced, egui, Slint,
ImGui or Clay without custom shaders. In a desktop environment they belong
in the compositor anyway.
