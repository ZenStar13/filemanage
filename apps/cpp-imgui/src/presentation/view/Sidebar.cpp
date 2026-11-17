#include "presentation/theme/Glyphs.hpp"
#include "presentation/theme/Palette.hpp"
#include "presentation/view/Views.hpp"

#include <imgui.h>

namespace fm::presentation::view {

void drawSidebar(const BrowserViewModel& vm, ActionQueue& actions, const Fonts& fonts) {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, palette::kSurface);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {dimens::kSm, dimens::kSm});
    ImGui::BeginChild(
        "##sidebar",
        {dimens::kSidebarWidth, ImGui::GetContentRegionAvail().y - dimens::kStatusBarHeight},
        ImGuiChildFlags_AlwaysUseWindowPadding);

    ImGui::Dummy({0, dimens::kXs});
    ImGui::SetCursorPosX(ImGui::GetCursorPosX() + dimens::kSm);
    ImGui::PushFont(fonts.bold, dimens::kFontTitle);
    ImGui::TextColored(palette::kGold, "Files");
    ImGui::PopFont();
    ImGui::Dummy({0, dimens::kXs});
    ImGui::PushFont(nullptr, dimens::kFontSmall);
    ImGui::TextColored(palette::kTextSecondary, "PLACES");
    ImGui::PopFont();

    ImGui::Dummy({0, dimens::kXs});
    ImGui::PushStyleVar(ImGuiStyleVar_SelectableTextAlign, {0, 0.5F});
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, {dimens::kSm, 2});
    for (const auto& place : vm.places()) {
        const bool active = place.path == vm.currentPath();
        const ImVec2 start = ImGui::GetCursorScreenPos();
        const ImVec2 size{ImGui::GetContentRegionAvail().x, 32};

        ImGui::PushID(place.label.c_str());
        ImGui::PushStyleColor(ImGuiCol_HeaderHovered, palette::kSurfaceRaised);
        if (ImGui::InvisibleButton("##place", size)) {
            actions.emplace_back(action::Open{place.path});
        }
        ImGui::PopStyleColor();
        const bool hovered = ImGui::IsItemHovered();
        ImGui::PopID();

        ImDrawList* draw = ImGui::GetWindowDrawList();
        const ImVec2 end{start.x + size.x, start.y + size.y};
        if (active) {
            draw->AddRectFilled(start, end, ImGui::GetColorU32(palette::kPurpleMuted),
                                dimens::kRadiusMd);
            draw->AddRect(start, end, ImGui::GetColorU32(palette::kPurple), dimens::kRadiusMd);
        } else if (hovered) {
            draw->AddRectFilled(start, end, ImGui::GetColorU32(palette::kSurfaceRaised),
                                dimens::kRadiusMd);
        }
        const float textY = start.y + (size.y - ImGui::GetFontSize()) / 2;
        draw->AddText({start.x + dimens::kSm, textY}, ImGui::GetColorU32(palette::kAqua),
                      glyphs::forPlace(place.kind));
        draw->AddText(
            {start.x + dimens::kSm + 26, textY},
            ImGui::GetColorU32(hovered && !active ? palette::kAqua : palette::kTextPrimary),
            place.label.c_str());
    }
    ImGui::PopStyleVar(2);

    ImGui::EndChild();
    ImGui::PopStyleVar();
    ImGui::PopStyleColor();
}

} // namespace fm::presentation::view
