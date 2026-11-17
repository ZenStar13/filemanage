#include "presentation/view/BrowserView.hpp"

#include "presentation/theme/Elevation.hpp"
#include "presentation/theme/Palette.hpp"

#include <imgui.h>

namespace fm::presentation {

ActionQueue BrowserView::draw(const BrowserViewModel& vm) {
    ActionQueue actions;
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);

    constexpr ImGuiWindowFlags kRootFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings |
        ImGuiWindowFlags_NoBringToFrontOnFocus;
    if (ImGui::Begin("##browser", nullptr, kRootFlags)) {
        bindShortcuts(actions);

        const float bodyHeight = ImGui::GetContentRegionAvail().y - dimens::kStatusBarHeight;
        view::drawSidebar(vm, actions, fonts_);
        const ImVec2 sidebarMin = ImGui::GetItemRectMin(); // child windows are items
        const ImVec2 sidebarMax = ImGui::GetItemRectMax();
        ImGui::SameLine(0, 0);

        ImGui::BeginChild("##main", {0, bodyHeight});
        view::drawToolbar(vm, actions);
        const ImVec2 toolbarMin = ImGui::GetItemRectMin();
        const ImVec2 toolbarMax = ImGui::GetItemRectMax();
        // Sections touch: the toolbar's shadow, not a gap, separates them.
        ImGui::SetCursorPosY(ImGui::GetCursorPosY() - ImGui::GetStyle().ItemSpacing.y);
        if (const auto& error = vm.error()) {
            view::drawErrorBanner(*error, actions);
        }
        table_.draw(vm, actions, fonts_);
        ImGui::EndChild();

        drawElevation({sidebarMin, sidebarMax}, {toolbarMin, toolbarMax}, table_.headerRect());

        view::drawStatusBar(vm);
    }
    ImGui::End();
    return actions;
}

void BrowserView::drawElevation(const view::FileTable::Rect& sidebar,
                                const view::FileTable::Rect& toolbar,
                                const std::optional<view::FileTable::Rect>& header) {
    // Shadows must cover the child windows of the main window but stay below
    // tooltips: a click-through overlay window drawn after the root does that.
    // Order, low to high: header < toolbar < sidebar.
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    constexpr ImGuiWindowFlags kOverlay =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoInputs | ImGuiWindowFlags_NoBackground |
        ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoFocusOnAppearing |
        ImGuiWindowFlags_NoNav;
    ImGui::Begin("##elevation", nullptr, kOverlay);
    ImDrawList* draw = ImGui::GetWindowDrawList();
    if (header) {
        elevation::castDown(draw, header->min, header->max, elevation::kHeader.shadow);
    }
    elevation::castDown(draw, toolbar.min, toolbar.max, elevation::kToolbar.shadow);
    elevation::castRight(draw, sidebar.min, sidebar.max, elevation::kSidebar.shadow);
    ImGui::End();
}

void BrowserView::bindShortcuts(ActionQueue& actions) {
    constexpr ImGuiInputFlags kGlobal = ImGuiInputFlags_RouteGlobal;
    constexpr ImGuiInputFlags kRepeat = ImGuiInputFlags_RouteGlobal | ImGuiInputFlags_Repeat;
    if (ImGui::Shortcut(ImGuiMod_Alt | ImGuiKey_LeftArrow, kGlobal)) {
        actions.emplace_back(action::GoBack{});
    }
    if (ImGui::Shortcut(ImGuiMod_Alt | ImGuiKey_RightArrow, kGlobal)) {
        actions.emplace_back(action::GoForward{});
    }
    if (ImGui::Shortcut(ImGuiMod_Alt | ImGuiKey_UpArrow, kGlobal) ||
        ImGui::Shortcut(ImGuiKey_Backspace, kGlobal)) {
        actions.emplace_back(action::GoUp{});
    }
    if (ImGui::Shortcut(ImGuiKey_F5, kGlobal)) {
        actions.emplace_back(action::Refresh{});
    }
    if (ImGui::Shortcut(ImGuiMod_Ctrl | ImGuiKey_H, kGlobal)) {
        actions.emplace_back(action::ToggleHidden{});
    }
    if (ImGui::Shortcut(ImGuiKey_UpArrow, kRepeat)) {
        actions.emplace_back(action::MoveSelection{-1});
    }
    if (ImGui::Shortcut(ImGuiKey_DownArrow, kRepeat)) {
        actions.emplace_back(action::MoveSelection{1});
    }
    if (ImGui::Shortcut(ImGuiKey_Enter, kGlobal) ||
        ImGui::Shortcut(ImGuiKey_KeypadEnter, kGlobal)) {
        actions.emplace_back(action::ActivateSelection{});
    }
    if (ImGui::Shortcut(ImGuiKey_Escape, kGlobal)) {
        actions.emplace_back(action::DismissError{});
    }
}

} // namespace fm::presentation
