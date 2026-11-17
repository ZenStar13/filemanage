#include "presentation/theme/Elevation.hpp"
#include "presentation/theme/Glyphs.hpp"
#include "presentation/theme/Palette.hpp"
#include "presentation/view/Views.hpp"

#include <imgui.h>
#include <string>

namespace fm::presentation::view {

namespace {

constexpr ImVec2 kToolButtonSize{36, 30};

/// Raised icon button with tooltip; disabled when `enabled` is false.
///
/// The glyph is drawn manually so it can be centred optically (ImGui centres
/// labels by advance width, which Nerd Font icons overflow). The shadow is
/// drawn into a draw-list channel *under* the button once we know whether the
/// button is pressed (pressed and disabled buttons sit flat).
bool toolButton(const char* id, const char* glyph, const char* tooltip, bool enabled,
                bool active = false) {
    ImDrawList* draw = ImGui::GetWindowDrawList();
    draw->ChannelsSplit(2);
    draw->ChannelsSetCurrent(1);

    ImGui::BeginDisabled(!enabled);
    ImGui::PushStyleColor(ImGuiCol_Button, active ? palette::kAqua : elevation::kButton.surface);
    const bool clicked = ImGui::Button(id, kToolButtonSize);
    ImGui::PopStyleColor();
    ImGui::EndDisabled();

    const ImVec2 min = ImGui::GetItemRectMin();
    const ImVec2 max = ImGui::GetItemRectMax();
    const bool hovered = ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled);
    const bool pressed = ImGui::IsItemActive();

    const ImVec4 color = active    ? palette::kTextOnAqua
                         : enabled ? palette::kAqua
                                   : palette::kBorder;
    const ImVec2 size = ImGui::CalcTextSize(glyph);
    const float shift =
        elevation::opticalOffset(glyph) * dimens::kFontBody / dimens::kLineHeightPerEm;
    draw->AddText({(min.x + max.x - size.x) / 2 - shift, (min.y + max.y - size.y) / 2},
                  ImGui::GetColorU32(color), glyph);

    draw->ChannelsSetCurrent(0);
    if (enabled && !pressed) {
        elevation::softShadow(draw, min, max, elevation::kButton.shadow, dimens::kRadiusMd);
    }
    draw->ChannelsMerge();

    if (hovered &&
        ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_DelayNormal)) {
        ImGui::SetTooltip("%s", tooltip);
    }
    return clicked && enabled;
}

void breadcrumbs(const BrowserViewModel& vm, ActionQueue& actions) {
    const auto segments = vm.currentPath().segments();
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4{0, 0, 0, 0});
    ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0.0F);
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, {dimens::kXs, 0});
    for (std::size_t i = 0; i < segments.size(); ++i) {
        ImGui::SameLine();
        if (i > 1) {
            ImGui::AlignTextToFramePadding();
            ImGui::PushFont(nullptr, dimens::fontSize(11.0F));
            ImGui::TextColored(palette::kPurple, "%s", glyphs::kChevronRight);
            ImGui::PopFont();
            ImGui::SameLine();
        }
        const bool isCurrent = i + 1 == segments.size();
        ImGui::PushStyleColor(ImGuiCol_Text, isCurrent ? palette::kGold : palette::kTextPrimary);
        ImGui::PushID(static_cast<int>(i));
        if (ImGui::Button(segments[i].label.c_str())) {
            actions.emplace_back(action::Open{segments[i].path});
        }
        ImGui::PopID();
        ImGui::PopStyleColor();
    }
    ImGui::PopStyleVar(2);
    ImGui::PopStyleColor();
}

} // namespace

void drawToolbar(const BrowserViewModel& vm, ActionQueue& actions) {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, elevation::kToolbar.surface);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding,
                        {dimens::kMd, (dimens::kToolbarHeight - kToolButtonSize.y) / 2});
    ImGui::BeginChild("##toolbar", {0, dimens::kToolbarHeight},
                      ImGuiChildFlags_AlwaysUseWindowPadding, ImGuiWindowFlags_NoScrollbar);

    if (toolButton("##back", glyphs::kBack, "Back (Alt+←)", vm.canGoBack())) {
        actions.emplace_back(action::GoBack{});
    }
    ImGui::SameLine(0, dimens::kXs);
    if (toolButton("##forward", glyphs::kForward, "Forward (Alt+→)", vm.canGoForward())) {
        actions.emplace_back(action::GoForward{});
    }
    ImGui::SameLine(0, dimens::kXs);
    if (toolButton("##up", glyphs::kUp, "Up (Backspace)", vm.canGoUp())) {
        actions.emplace_back(action::GoUp{});
    }
    ImGui::SameLine(0, dimens::kXs);
    if (toolButton("##refresh", glyphs::kRefresh, "Refresh (F5)", true)) {
        actions.emplace_back(action::Refresh{});
    }
    ImGui::SameLine(0, dimens::kMd);

    breadcrumbs(vm, actions);

    ImGui::SameLine(ImGui::GetWindowWidth() - kToolButtonSize.x - dimens::kMd);
    if (toolButton("##hidden", vm.showsHidden() ? glyphs::kEye : glyphs::kEyeSlash,
                   "Show hidden files (Ctrl+H)", true, vm.showsHidden())) {
        actions.emplace_back(action::ToggleHidden{});
    }

    ImGui::EndChild();
    ImGui::PopStyleVar();
    ImGui::PopStyleColor();
}

void drawErrorBanner(const domain::FsError& error, ActionQueue& actions) {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, palette::kPurpleMuted);
    ImGui::PushStyleColor(ImGuiCol_Border, palette::kDanger);
    ImGui::PushStyleVar(ImGuiStyleVar_ChildRounding, dimens::kRadiusMd);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {dimens::kMd, dimens::kSm});
    ImGui::SetCursorPos(
        {ImGui::GetCursorPosX() + dimens::kSm, ImGui::GetCursorPosY() + dimens::kSm});
    ImGui::BeginChild("##error", {ImGui::GetContentRegionAvail().x - dimens::kSm, 0},
                      ImGuiChildFlags_Borders | ImGuiChildFlags_AutoResizeY |
                          ImGuiChildFlags_AlwaysUseWindowPadding);
    ImGui::AlignTextToFramePadding();
    ImGui::TextColored(palette::kDanger, "%s", glyphs::kWarning);
    ImGui::SameLine();
    ImGui::TextUnformatted(error.message().c_str());
    ImGui::SameLine(ImGui::GetWindowWidth() - 90);
    if (ImGui::Button("Dismiss")) {
        actions.emplace_back(action::DismissError{});
    }
    ImGui::EndChild();
    ImGui::PopStyleVar(2);
    ImGui::PopStyleColor(2);
    ImGui::Dummy({0, dimens::kXs});
}

} // namespace fm::presentation::view
