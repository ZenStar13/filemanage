#include "presentation/Format.hpp"
#include "presentation/theme/Palette.hpp"
#include "presentation/view/Views.hpp"

#include <imgui.h>

namespace fm::presentation::view {

void drawStatusBar(const BrowserViewModel& vm) {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, palette::kSurface);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {dimens::kMd, 0});
    ImGui::BeginChild("##status", {0, dimens::kStatusBarHeight},
                      ImGuiChildFlags_AlwaysUseWindowPadding, ImGuiWindowFlags_NoScrollbar);

    ImGui::GetWindowDrawList()->AddLine(
        ImGui::GetWindowPos(),
        {ImGui::GetWindowPos().x + ImGui::GetWindowWidth(), ImGui::GetWindowPos().y},
        ImGui::GetColorU32(palette::kBorder));
    ImGui::PushFont(nullptr, dimens::kFontSmall);
    ImGui::SetCursorPosY((dimens::kStatusBarHeight - ImGui::GetFontSize()) / 2);
    if (const auto summary = vm.summary()) {
        ImGui::TextColored(palette::kGold, "%s",
                           format::summary(*summary, vm.showsHidden()).c_str());
    }
    const std::string right = vm.isLoading() ? "Loading…" : vm.currentPath().string();
    const float width = ImGui::CalcTextSize(right.c_str()).x;
    ImGui::SameLine(ImGui::GetWindowWidth() - width - dimens::kMd);
    ImGui::TextColored(vm.isLoading() ? palette::kPurple : palette::kTextSecondary, "%s",
                       right.c_str());
    ImGui::PopFont();

    ImGui::EndChild();
    ImGui::PopStyleVar();
    ImGui::PopStyleColor();
}

} // namespace fm::presentation::view
