#pragma once

#include <cstdint>
#include <imgui.h>

/// Palette and layout tokens mirrored from `design/tokens.json`.
namespace fm::presentation::palette {

[[nodiscard]] constexpr ImVec4 rgb(std::uint32_t hex, float alpha = 1.0F) {
    return {static_cast<float>((hex >> 16U) & 0xFFU) / 255.0F,
            static_cast<float>((hex >> 8U) & 0xFFU) / 255.0F,
            static_cast<float>(hex & 0xFFU) / 255.0F, alpha};
}

inline constexpr ImVec4 kBackground = rgb(0x0B1A20);
inline constexpr ImVec4 kSurface = rgb(0x10252D);
inline constexpr ImVec4 kSurfaceRaised = rgb(0x16323C);
inline constexpr ImVec4 kBorder = rgb(0x1F4651);

inline constexpr ImVec4 kAqua = rgb(0x00E5E0);
inline constexpr ImVec4 kAquaMuted = rgb(0x0B6F73);
inline constexpr ImVec4 kAquaSubtle = rgb(0x0E3A40);

inline constexpr ImVec4 kPurple = rgb(0xA06CFF);
inline constexpr ImVec4 kPurpleMuted = rgb(0x3C2A66);

inline constexpr ImVec4 kGold = rgb(0xFFC94D);
inline constexpr ImVec4 kGoldMuted = rgb(0x6B5520);

inline constexpr ImVec4 kTextPrimary = rgb(0xE8FBFB);
inline constexpr ImVec4 kTextSecondary = rgb(0x8DB6BC);
inline constexpr ImVec4 kTextOnAqua = rgb(0x04201F);
inline constexpr ImVec4 kDanger = rgb(0xFF6B8A);

// Tool buttons: strongly defined borders.
inline constexpr ImVec4 kButtonBorder = rgb(0x1A9C98);
inline constexpr ImVec4 kButtonBorderHover = kPurple;
inline constexpr ImVec4 kButtonBorderPressed = kAqua;
inline constexpr ImVec4 kButtonBorderDisabled = kBorder;
// Location field, menus, window controls.
inline constexpr ImVec4 kLocationSurface = rgb(0x0E2128);
inline constexpr ImVec4 kMenuSurface = rgb(0x1B3A45);
inline constexpr ImVec4 kWindowControlHover = rgb(0x24495A);
inline constexpr ImVec4 kCloseHover = rgb(0xE0405E);

} // namespace fm::presentation::palette

namespace fm::presentation::dimens {

inline constexpr float kXs = 4.0F;
inline constexpr float kSm = 8.0F;
inline constexpr float kMd = 12.0F;
inline constexpr float kLg = 16.0F;
inline constexpr float kRadiusSm = 4.0F;
inline constexpr float kRadiusMd = 8.0F;
inline constexpr float kSidebarWidth = 220.0F;
inline constexpr float kRowHeight = 28.0F;
inline constexpr float kActionRowHeight = 44.0F;
inline constexpr float kLocationRowHeight = 40.0F;
inline constexpr float kToolbarHeight = kActionRowHeight + kLocationRowHeight;
inline constexpr float kLocationFieldHeight = 30.0F;
inline constexpr float kTitleBarHeight = 36.0F;
inline constexpr float kWindowControlWidth = 46.0F;
inline constexpr float kButtonBorderWidth = 2.0F;
inline constexpr float kStatusBarHeight = 26.0F;

// Design tokens give font sizes in em pixels (like CSS, Flutter, iced...).
// Dear ImGui sizes fonts by line height (ascent - descent) instead, which for
// 0xProto is 1.56 em ((1130 + 430) / 1000 units), so we convert once here.
inline constexpr float kLineHeightPerEm = 1.56F;
[[nodiscard]] constexpr float fontSize(float em) {
    return em * kLineHeightPerEm;
}

inline constexpr float kFontSmall = fontSize(13.0F);
inline constexpr float kFontBody = fontSize(15.0F);
inline constexpr float kFontTitle = fontSize(18.0F);

} // namespace fm::presentation::dimens
