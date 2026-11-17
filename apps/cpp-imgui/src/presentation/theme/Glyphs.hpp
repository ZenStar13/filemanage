#pragma once

#include "domain/FileEntry.hpp"
#include "domain/Place.hpp"

#include <imgui.h>

namespace fm::presentation::glyphs {

// Nerd Font codepoints (Font Awesome range), UTF-8 encoded.
inline constexpr const char* kFolder = "";
inline constexpr const char* kFile = "";
inline constexpr const char* kSymlink = "";
inline constexpr const char* kBack = "";
inline constexpr const char* kForward = "";
inline constexpr const char* kUp = "";
inline constexpr const char* kRefresh = "";
inline constexpr const char* kEye = "";
inline constexpr const char* kEyeSlash = "";
inline constexpr const char* kChevronRight = "";
inline constexpr const char* kWarning = "";

struct Icon {
    const char* glyph;
    ImVec4 color;
};

/// Aqua folders, purple links, gold media, neutral everything else.
[[nodiscard]] Icon forEntry(const domain::FileEntry& entry);
[[nodiscard]] const char* forPlace(domain::PlaceKind kind);

} // namespace fm::presentation::glyphs
