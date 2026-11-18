#include "presentation/theme/Elevation.hpp"
#include "presentation/theme/Glyphs.hpp"
#include "presentation/theme/Palette.hpp"
#include "presentation/view/Views.hpp"

#include <array>
#include <imgui.h>

namespace fm::presentation::view {

namespace {

constexpr float kMenuFont = dimens::fontSize(14.0F);

/// Minimise / maximise / close: flat, full-height buttons; close turns red.
bool windowControl(const char* id, const char* glyph, bool isClose) {
    const ImVec2 size{dimens::kWindowControlWidth, dimens::kTitleBarHeight};
    const ImVec2 min = ImGui::GetCursorScreenPos();
    const bool clicked = ImGui::InvisibleButton(id, size);
    const bool hovered = ImGui::IsItemHovered();
    const ImVec2 max{min.x + size.x, min.y + size.y};
    ImDrawList* draw = ImGui::GetWindowDrawList();
    if (hovered) {
        draw->AddRectFilled(
            min, max,
            ImGui::GetColorU32(isClose ? palette::kCloseHover : palette::kWindowControlHover));
    }
    const ImVec4 color =
        hovered ? (isClose ? ImVec4{1, 1, 1, 1} : palette::kAqua) : palette::kTextPrimary;
    const ImVec2 text = ImGui::CalcTextSize(glyph);
    const float shift =
        elevation::opticalOffset(glyph) * dimens::kFontBody / dimens::kLineHeightPerEm;
    draw->AddText({(min.x + max.x - text.x) / 2 - shift, (min.y + max.y - text.y) / 2},
                  ImGui::GetColorU32(color), glyph);
    return clicked;
}

} // namespace

TitleBarResult drawTitleBar(const BrowserViewModel& vm, bool maximized, ActionQueue& actions,
                            WindowRequests& window) {
    TitleBarResult result{};
    using Kind = WindowRequest::Kind;

    // The menu bar's height derives from FramePadding.y at Begin time.
    ImGui::PushStyleVar(ImGuiStyleVar_FramePadding,
                        {10, (dimens::kTitleBarHeight - kMenuFont) / 2});
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {0, 0});
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, {0, 0});
    ImGui::PushStyleColor(ImGuiCol_ChildBg, elevation::kTitleBar.surface);
    ImGui::BeginChild("##titlebar", {0, dimens::kTitleBarHeight}, ImGuiChildFlags_None,
                      ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoScrollbar);
    result.min = ImGui::GetWindowPos();
    result.max = {result.min.x + ImGui::GetWindowWidth(), result.min.y + dimens::kTitleBarHeight};

    if (ImGui::BeginMenuBar()) {
        // Dropdowns take the style active when they open: give them padding
        // and readable shortcut hints (ImGui draws those with TextDisabled).
        ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, {dimens::kSm, dimens::kXs});
        ImGui::PushStyleVar(ImGuiStyleVar_FramePadding, {dimens::kSm, 4});
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {dimens::kSm, dimens::kSm});
        ImGui::PushStyleColor(ImGuiCol_TextDisabled, palette::kTextSecondary);
        ImGui::PushFont(nullptr, kMenuFont);

        ImGui::SetCursorPosX(12);
        ImGui::TextColored(palette::kAqua, "%s", glyphs::kAppIcon);
        ImGui::SameLine(0, 18); // the icon's ink overflows its advance width

        if (ImGui::BeginMenu("File")) {
            if (ImGui::MenuItem("Open Location…", "Ctrl+L")) {
                actions.emplace_back(action::StartEditLocation{});
            }
            if (ImGui::MenuItem("Refresh", "F5")) {
                actions.emplace_back(action::Refresh{});
            }
            ImGui::Separator();
            if (ImGui::MenuItem("Quit", "Ctrl+Q")) {
                window.push_back({.kind = Kind::Close});
            }
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("View")) {
            if (ImGui::MenuItem("Show Hidden Files", "Ctrl+H", vm.showsHidden())) {
                actions.emplace_back(action::ToggleHidden{});
            }
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("Go")) {
            if (ImGui::MenuItem("Back", "Alt+Left", false, vm.canGoBack())) {
                actions.emplace_back(action::GoBack{});
            }
            if (ImGui::MenuItem("Forward", "Alt+Right", false, vm.canGoForward())) {
                actions.emplace_back(action::GoForward{});
            }
            if (ImGui::MenuItem("Up", "Alt+Up", false, vm.canGoUp())) {
                actions.emplace_back(action::GoUp{});
            }
            if (ImGui::MenuItem("Home", "Alt+Home")) {
                actions.emplace_back(action::GoHome{});
            }
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("Help")) {
            if (ImGui::MenuItem("About Files")) {
                result.openAbout = true;
            }
            ImGui::EndMenu();
        }

        // Centred title (current folder name).
        const std::string title = vm.currentPath().name();
        ImGui::PushFont(nullptr, kMenuFont);
        const ImVec2 titleSize = ImGui::CalcTextSize(title.c_str());
        ImGui::GetWindowDrawList()->AddText(
            {result.min.x + (ImGui::GetWindowWidth() - titleSize.x) / 2,
             result.min.y + (dimens::kTitleBarHeight - titleSize.y) / 2},
            ImGui::GetColorU32(palette::kGold), title.c_str());
        ImGui::PopFont();

        ImGui::PopFont();
        ImGui::PopStyleColor();
        ImGui::PopStyleVar(3);

        // Window controls, flush right and full height.
        ImGui::SetCursorScreenPos({result.max.x - (3 * dimens::kWindowControlWidth), result.min.y});
        ImGui::PushFont(nullptr, dimens::kFontBody);
        if (windowControl("##minimize", glyphs::kChromeMinimize, false)) {
            window.push_back({.kind = Kind::Minimize});
        }
        ImGui::SameLine(0, 0);
        if (windowControl("##maximize",
                          maximized ? glyphs::kChromeRestore : glyphs::kChromeMaximize, false)) {
            window.push_back({.kind = Kind::ToggleMaximize});
        }
        ImGui::SameLine(0, 0);
        if (windowControl("##close", glyphs::kChromeClose, true)) {
            window.push_back({.kind = Kind::Close});
        }
        ImGui::PopFont();

        // Empty title-bar area: drag to move, double-click to maximise.
        const bool overEmptyArea = ImGui::IsWindowHovered() && !ImGui::IsAnyItemHovered() &&
                                   !ImGui::IsPopupOpen("", ImGuiPopupFlags_AnyPopupId);
        if (overEmptyArea && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
            window.push_back({.kind = Kind::ToggleMaximize});
        } else if (overEmptyArea && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
            window.push_back({.kind = Kind::BeginMove});
        }
        ImGui::EndMenuBar();
    }

    ImGui::EndChild();
    ImGui::PopStyleColor();
    ImGui::PopStyleVar(3);
    return result;
}

void drawAboutModal(bool& open) {
    constexpr const char* kId = "About Files";
    if (open && !ImGui::IsPopupOpen(kId)) {
        ImGui::OpenPopup(kId);
    }
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->GetCenter(), ImGuiCond_Always, {0.5F, 0.5F});
    ImGui::SetNextWindowSize({440, 0});
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, {24, 24});
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, {dimens::kSm, dimens::kMd});
    ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, dimens::kRadiusMd);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1);
    if (ImGui::BeginPopupModal(kId, &open,
                               ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoMove |
                                   ImGuiWindowFlags_NoSavedSettings)) {
        ImGui::PushFont(nullptr, dimens::kFontTitle);
        ImGui::TextColored(palette::kAqua, "%s", glyphs::kAppIcon);
        ImGui::SameLine(0, dimens::kMd);
        ImGui::TextColored(palette::kGold, "Files");
        ImGui::PopFont();
        ImGui::TextColored(palette::kPurple, "C++23 · Dear ImGui 1.93");
        ImGui::PushStyleColor(ImGuiCol_Text, palette::kTextSecondary);
        ImGui::TextWrapped(
            "A first-draft file manager, built six times to compare Linux GUI stacks.");
        ImGui::TextWrapped("Aqua · purple · gold  —  0xProto Nerd Font");
        ImGui::PopStyleColor();
        ImGui::SetCursorPosX(ImGui::GetWindowWidth() - 24 - 90);
        ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, dimens::kButtonBorderWidth);
        ImGui::PushStyleColor(ImGuiCol_Border, palette::kButtonBorder);
        ImGui::PushStyleColor(ImGuiCol_Text, palette::kAqua);
        if (ImGui::Button("Close", {90, 0}) || ImGui::IsKeyPressed(ImGuiKey_Escape)) {
            open = false;
            ImGui::CloseCurrentPopup();
        }
        ImGui::PopStyleColor(2);
        ImGui::PopStyleVar();
        ImGui::EndPopup();
    }
    ImGui::PopStyleVar(4);
}

} // namespace fm::presentation::view
