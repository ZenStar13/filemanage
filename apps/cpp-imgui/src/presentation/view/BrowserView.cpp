#include "presentation/view/BrowserView.hpp"

#include "presentation/theme/Elevation.hpp"
#include "presentation/theme/Palette.hpp"

#include <imgui.h>
#include <imgui_internal.h> // ClosePopupsExceptModals

namespace fm::presentation {

BrowserView::Output BrowserView::draw(const BrowserViewModel& vm, bool maximized) {
    Output out;
    ActionQueue& actions = out.actions;
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);

    constexpr ImGuiWindowFlags kRootFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings |
        ImGuiWindowFlags_NoBringToFrontOnFocus;
    if (ImGui::Begin("##browser", nullptr, kRootFlags)) {
        bindShortcuts(actions, out.window);

        const auto title = view::drawTitleBar(vm, maximized, actions, out.window);
        aboutOpen_ = aboutOpen_ || title.openAbout;
        // Sections touch: shadows, not gaps, separate them.
        ImGui::SetCursorPosY(ImGui::GetCursorPosY() - ImGui::GetStyle().ItemSpacing.y);

        const float bodyHeight = ImGui::GetContentRegionAvail().y - dimens::kStatusBarHeight;
        view::drawSidebar(vm, actions, fonts_);
        const ImVec2 sidebarMin = ImGui::GetItemRectMin(); // child windows are items
        const ImVec2 sidebarMax = ImGui::GetItemRectMax();
        ImGui::SameLine(0, 0);

        ImGui::BeginChild("##main", {0, bodyHeight});
        toolbar_.draw(vm, actions);
        const ImVec2 toolbarMin = ImGui::GetItemRectMin();
        const ImVec2 toolbarMax = ImGui::GetItemRectMax();
        // Sections touch: the toolbar's shadow, not a gap, separates them.
        ImGui::SetCursorPosY(ImGui::GetCursorPosY() - ImGui::GetStyle().ItemSpacing.y);
        if (const auto& error = vm.error()) {
            view::drawErrorBanner(*error, actions);
        }
        table_.draw(vm, actions, fonts_);
        ImGui::EndChild();

        drawElevation({title.min, title.max}, {sidebarMin, sidebarMax}, {toolbarMin, toolbarMax},
                      table_.headerRect());

        view::drawStatusBar(vm);
    }
    ImGui::End();

    view::drawAboutModal(aboutOpen_);
    if (!maximized) {
        resizeEdges(out.window);
    }
    return out;
}

void BrowserView::resizeEdges(WindowRequests& window) {
    // Undecorated windows have no WM borders: a 5px band along each edge
    // starts a resize (corners combine two edges).
    constexpr float kEdge = 5.0F;
    if (ImGui::IsPopupOpen("", ImGuiPopupFlags_AnyPopupId)) {
        return;
    }
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    const ImVec2 mouse = ImGui::GetMousePos();
    const ImVec2 min = viewport->Pos;
    const ImVec2 max{min.x + viewport->Size.x, min.y + viewport->Size.y};
    if (mouse.x < min.x || mouse.y < min.y || mouse.x > max.x || mouse.y > max.y) {
        return;
    }
    unsigned edges = 0;
    edges |= mouse.y - min.y < kEdge ? WindowRequest::Top : 0U;
    edges |= max.y - mouse.y < kEdge ? WindowRequest::Bottom : 0U;
    edges |= mouse.x - min.x < kEdge ? WindowRequest::Left : 0U;
    edges |= max.x - mouse.x < kEdge ? WindowRequest::Right : 0U;
    if (edges == 0) {
        return;
    }
    const bool horizontal = (edges & (WindowRequest::Left | WindowRequest::Right)) != 0U;
    const bool vertical = (edges & (WindowRequest::Top | WindowRequest::Bottom)) != 0U;
    const bool nwse = edges == (WindowRequest::Top | WindowRequest::Left) ||
                      edges == (WindowRequest::Bottom | WindowRequest::Right);
    ImGui::SetMouseCursor(horizontal && vertical
                              ? (nwse ? ImGuiMouseCursor_ResizeNWSE : ImGuiMouseCursor_ResizeNESW)
                          : horizontal ? ImGuiMouseCursor_ResizeEW
                                       : ImGuiMouseCursor_ResizeNS);
    if (ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
        window.push_back({.kind = WindowRequest::Kind::BeginResize, .edges = edges});
    }
}

void BrowserView::drawElevation(const view::FileTable::Rect& title,
                                const view::FileTable::Rect& sidebar,
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
    elevation::castDown(draw, title.min, title.max, elevation::kTitleBar.shadow);
    ImGui::End();
}

void BrowserView::bindShortcuts(ActionQueue& actions, WindowRequests& window) {
    if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
        // Keyboard nav is off (our own selection model), so ImGui won't close
        // menus on Escape by itself.
        if (ImGui::IsPopupOpen("", ImGuiPopupFlags_AnyPopupId)) {
            ImGui::ClosePopupsExceptModals();
        } else {
            actions.emplace_back(action::Cancel{});
        }
    }
    // While a text field has focus, keys belong to it.
    if (ImGui::GetIO().WantTextInput) {
        return;
    }
    if (ImGui::Shortcut(ImGuiMod_Ctrl | ImGuiKey_Q, ImGuiInputFlags_RouteGlobal)) {
        window.push_back({.kind = WindowRequest::Kind::Close});
    }
    if (ImGui::Shortcut(ImGuiMod_Ctrl | ImGuiKey_L, ImGuiInputFlags_RouteGlobal)) {
        actions.emplace_back(action::StartEditLocation{});
    }
    if (ImGui::Shortcut(ImGuiMod_Alt | ImGuiKey_Home, ImGuiInputFlags_RouteGlobal)) {
        actions.emplace_back(action::GoHome{});
    }
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
}

} // namespace fm::presentation
