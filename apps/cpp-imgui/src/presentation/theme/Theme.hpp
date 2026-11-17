#pragma once

#include <filesystem>

struct ImFont;

namespace fm::presentation {

/// Fonts loaded into the ImGui atlas.
struct Fonts {
    ImFont* regular{nullptr};
    ImFont* bold{nullptr};
};

/// Applies the Aqua palette and metrics to the current ImGui style.
void applyTheme();

/// Loads 0xProto Nerd Font from `fontDir`. ImGui >= 1.92 rasterises glyphs on
/// demand, so the Nerd Font icon range needs no explicit glyph ranges.
[[nodiscard]] Fonts loadFonts(const std::filesystem::path& fontDir);

} // namespace fm::presentation
