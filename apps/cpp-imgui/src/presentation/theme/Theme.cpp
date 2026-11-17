#include "presentation/theme/Theme.hpp"

#include "presentation/theme/Palette.hpp"

#include <imgui.h>

namespace fm::presentation {

using namespace palette;

void applyTheme() {
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowPadding = {0, 0};
    style.WindowBorderSize = 0;
    style.WindowRounding = 0;
    style.FramePadding = {dimens::kSm, 3.0F};
    style.FrameRounding = dimens::kRadiusMd;
    style.FrameBorderSize = 1;
    style.ItemSpacing = {dimens::kSm, dimens::kXs};
    style.CellPadding = {dimens::kSm, 0};
    style.ScrollbarSize = 12;
    style.ScrollbarRounding = dimens::kRadiusMd;
    style.TabRounding = dimens::kRadiusSm;
    style.SelectableTextAlign = {0, 0.5F};
    style.FontSizeBase = dimens::kFontBody;

    ImVec4* c = style.Colors;
    c[ImGuiCol_Text] = kTextPrimary;
    c[ImGuiCol_TextDisabled] = kBorder;
    c[ImGuiCol_WindowBg] = kBackground;
    c[ImGuiCol_ChildBg] = kBackground;
    c[ImGuiCol_PopupBg] = kSurfaceRaised;
    c[ImGuiCol_Border] = kBorder;
    c[ImGuiCol_FrameBg] = kSurfaceRaised;
    c[ImGuiCol_FrameBgHovered] = kPurpleMuted;
    c[ImGuiCol_FrameBgActive] = kAquaMuted;
    c[ImGuiCol_Button] = kSurfaceRaised;
    c[ImGuiCol_ButtonHovered] = kPurpleMuted;
    c[ImGuiCol_ButtonActive] = kAquaMuted;
    c[ImGuiCol_Header] = kAquaSubtle;
    c[ImGuiCol_HeaderHovered] = kPurpleMuted;
    c[ImGuiCol_HeaderActive] = kAquaMuted;
    c[ImGuiCol_ScrollbarBg] = kBackground;
    c[ImGuiCol_ScrollbarGrab] = kAquaMuted;
    c[ImGuiCol_ScrollbarGrabHovered] = kAqua;
    c[ImGuiCol_ScrollbarGrabActive] = kAqua;
    c[ImGuiCol_TableHeaderBg] = kSurfaceRaised;
    c[ImGuiCol_TableBorderStrong] = kBorder;
    c[ImGuiCol_TableBorderLight] = kBorder;
    c[ImGuiCol_TableRowBg] = {0, 0, 0, 0};
    c[ImGuiCol_TableRowBgAlt] = rgb(0x10252D, 0.35F);
    c[ImGuiCol_Separator] = kBorder;
    c[ImGuiCol_ResizeGrip] = kAquaMuted;
    c[ImGuiCol_ResizeGripHovered] = kAqua;
    c[ImGuiCol_NavCursor] = kAqua;
    c[ImGuiCol_CheckMark] = kAqua;
}

Fonts loadFonts(const std::filesystem::path& fontDir) {
    ImGuiIO& io = ImGui::GetIO();
    Fonts fonts;
    const auto regular = fontDir / "0xProtoNerdFont-Regular.ttf";
    const auto bold = fontDir / "0xProtoNerdFont-Bold.ttf";
    if (std::filesystem::exists(regular)) {
        fonts.regular = io.Fonts->AddFontFromFileTTF(regular.c_str(), dimens::kFontBody);
    }
    if (std::filesystem::exists(bold)) {
        fonts.bold = io.Fonts->AddFontFromFileTTF(bold.c_str(), dimens::kFontBody);
    }
    if (fonts.regular == nullptr) {
        fonts.regular = io.Fonts->AddFontDefault(); // Degrade gracefully.
    }
    if (fonts.bold == nullptr) {
        fonts.bold = fonts.regular;
    }
    io.FontDefault = fonts.regular;
    return fonts;
}

} // namespace fm::presentation
