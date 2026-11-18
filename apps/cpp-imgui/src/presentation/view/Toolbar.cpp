#include "presentation/theme/Elevation.hpp"
#include "presentation/theme/Glyphs.hpp"
#include "presentation/theme/Palette.hpp"
#include "presentation/view/Views.hpp"

#include <imgui.h>
#include <misc/cpp/imgui_stdlib.h>
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

    // Strongly defined 2px border, coloured by state.
    const ImVec4 border = active     ? palette::kAqua
                          : !enabled ? palette::kButtonBorderDisabled
                          : pressed  ? palette::kButtonBorderPressed
                          : hovered  ? palette::kButtonBorderHover
                                     : palette::kButtonBorder;
    const float inset = dimens::kButtonBorderWidth / 2;
    draw->AddRect({min.x + inset, min.y + inset}, {max.x - inset, max.y - inset},
                  ImGui::GetColorU32(border), dimens::kRadiusMd, dimens::kButtonBorderWidth);

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
        if (i > 0) {
            ImGui::SameLine();
        }
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

void Toolbar::draw(const BrowserViewModel& vm, ActionQueue& actions) {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, elevation::kToolbar.surface);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {dimens::kMd, 0});
    ImGui::BeginChild("##toolbar", {0, dimens::kToolbarHeight},
                      ImGuiChildFlags_AlwaysUseWindowPadding, ImGuiWindowFlags_NoScrollbar);

    // ---- Action row
    ImGui::SetCursorPosY((dimens::kActionRowHeight - kToolButtonSize.y) / 2);
    if (toolButton("##back", glyphs::kBack, "Back (Alt+\u2190)", vm.canGoBack())) {
        actions.emplace_back(action::GoBack{});
    }
    ImGui::SameLine(0, dimens::kXs);
    if (toolButton("##forward", glyphs::kForward, "Forward (Alt+\u2192)", vm.canGoForward())) {
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
    ImGui::SameLine(ImGui::GetWindowWidth() - kToolButtonSize.x - dimens::kMd);
    if (toolButton("##hidden", vm.showsHidden() ? glyphs::kEye : glyphs::kEyeSlash,
                   "Show hidden files (Ctrl+H)", true, vm.showsHidden())) {
        actions.emplace_back(action::ToggleHidden{});
    }

    // ---- Location row
    locationRow(vm, actions);

    ImGui::EndChild();
    ImGui::PopStyleVar();
    ImGui::PopStyleColor();
}

/// Breadcrumbs inside an inset field; clicking the field (or the pencil, or
/// Ctrl+L) switches to a text input. Enter navigates; Escape or clicking
/// elsewhere cancels.
void Toolbar::locationRow(const BrowserViewModel& vm, ActionQueue& actions) {
    const float rowTop = dimens::kActionRowHeight;
    const float fieldWidth = ImGui::GetContentRegionAvail().x - kToolButtonSize.x - dimens::kSm;
    ImGui::SetCursorPos({dimens::kMd, rowTop});
    const ImVec2 fieldMin = ImGui::GetCursorScreenPos();
    const ImVec2 fieldMax{fieldMin.x + fieldWidth, fieldMin.y + dimens::kLocationFieldHeight};
    const bool editing = vm.isEditingLocation();

    if (editing) {
        if (!wasEditing_) {
            draft_ = vm.currentPath().string();
            ImGui::SetKeyboardFocusHere();
        }
        ImGui::PushStyleColor(ImGuiCol_FrameBg, palette::kLocationSurface);
        ImGui::PushStyleColor(ImGuiCol_Border, palette::kAqua);
        ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 2.0F);
        ImGui::PushStyleVar(
            ImGuiStyleVar_FramePadding,
            {dimens::kSm, (dimens::kLocationFieldHeight - ImGui::GetFontSize()) / 2});
        ImGui::SetNextItemWidth(fieldWidth);
        const bool submitted = ImGui::InputTextWithHint(
            "##location", "Type a folder path, e.g. ~/Documents or /etc", &draft_,
            ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_AutoSelectAll);
        if (submitted) {
            actions.emplace_back(action::SubmitLocation{draft_});
        } else if (wasEditing_ && ImGui::IsItemDeactivated()) {
            actions.emplace_back(action::Cancel{}); // Escape or focus lost
        }
        ImGui::PopStyleVar(2);
        ImGui::PopStyleColor(2);
    } else {
        ImDrawList* draw = ImGui::GetWindowDrawList();
        draw->AddRectFilled(fieldMin, fieldMax, ImGui::GetColorU32(palette::kLocationSurface),
                            dimens::kRadiusMd);
        draw->AddRect(fieldMin, fieldMax, ImGui::GetColorU32(palette::kBorder), dimens::kRadiusMd);
        ImGui::SetCursorScreenPos({fieldMin.x + dimens::kXs, fieldMin.y});
        ImGui::PushStyleVar(
            ImGuiStyleVar_FramePadding,
            {dimens::kSm, (dimens::kLocationFieldHeight - ImGui::GetFontSize()) / 2});
        breadcrumbs(vm, actions);
        ImGui::PopStyleVar();
        if (ImGui::IsMouseHoveringRect(fieldMin, fieldMax) && !ImGui::IsAnyItemHovered()) {
            ImGui::SetMouseCursor(ImGuiMouseCursor_TextInput);
            if (ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
                actions.emplace_back(action::StartEditLocation{});
            }
        }
    }
    wasEditing_ = editing;

    ImGui::SetCursorScreenPos({fieldMax.x + dimens::kSm, fieldMin.y});
    if (editing) {
        if (toolButton("##go", glyphs::kForward, "Go (Enter)", true)) {
            actions.emplace_back(action::SubmitLocation{draft_});
        }
    } else if (toolButton("##edit", glyphs::kEdit, "Type a location (Ctrl+L)", true)) {
        actions.emplace_back(action::StartEditLocation{});
    }
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
