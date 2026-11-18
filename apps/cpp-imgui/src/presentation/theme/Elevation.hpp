#pragma once

#include "presentation/theme/Palette.hpp"

#include <imgui.h>
#include <string_view>

/// Elevation scale (`design/tokens.json` → `elevation`). Higher sections are
/// lighter and cast a shadow onto lower ones:
/// file list (0) < column header (1) < toolbar (2) < places sidebar (3).
///
/// Dear ImGui has no shadows, so they are drawn here: straight section edges
/// use cheap gradient strips, rounded buttons use stacked translucent rects.
namespace fm::presentation::elevation {

struct Shadow {
    float x;
    float y;
    float blur;
    float alpha;
};

struct Level {
    ImVec4 surface;
    Shadow shadow;
};

inline constexpr Level kFileList{palette::rgb(0x0B1A20), {0, 0, 0, 0}};
inline constexpr Level kHeader{palette::rgb(0x10262E), {0, 1, 4, 0.35F}};
inline constexpr Level kToolbar{palette::rgb(0x132C35), {0, 2, 8, 0.45F}};
inline constexpr Level kSidebar{palette::rgb(0x17323C), {3, 0, 14, 0.55F}};
inline constexpr Level kTitleBar{palette::rgb(0x1B3A45), {0, 2, 10, 0.5F}};
inline constexpr Level kButton{palette::rgb(0x1D3D49), {0, 1, 3, 0.45F}};

/// Shadow cast to the right of `caster`'s right edge (e.g. the sidebar).
void castRight(ImDrawList* draw, const ImVec2& casterMin, const ImVec2& casterMax,
               const Shadow& shadow);

/// Shadow cast below `caster`'s bottom edge (e.g. toolbar, column header).
void castDown(ImDrawList* draw, const ImVec2& casterMin, const ImVec2& casterMax,
              const Shadow& shadow);

/// Soft drop shadow under a rounded rectangle; draw it *before* the shape.
void softShadow(ImDrawList* draw, const ImVec2& min, const ImVec2& max, const Shadow& shadow,
                float rounding);

/// Optical-centre correction in em (`design/tokens.json` → `glyphCentering`).
/// Nerd Font icons overflow their advance width to the right; shift them
/// left by `opticalOffset(glyph) * fontSize` to centre them in a button.
[[nodiscard]] float opticalOffset(std::string_view glyph);

} // namespace fm::presentation::elevation
