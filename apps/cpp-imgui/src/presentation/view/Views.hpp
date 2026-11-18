#pragma once

#include "presentation/theme/Theme.hpp"
#include "presentation/view/WindowRequest.hpp"
#include "presentation/viewmodel/Action.hpp"
#include "presentation/viewmodel/BrowserViewModel.hpp"

#include <cstdint>
#include <imgui.h>
#include <optional>
#include <string>

/// Sub-views of the browser screen. Each is a pure function of the (const)
/// view model that records user intents into the action queue.
namespace fm::presentation::view {

/// Custom title bar: menus, centred title, window controls, drag area.
struct TitleBarResult {
    ImVec2 min;
    ImVec2 max;
    bool openAbout{false};
};
[[nodiscard]] TitleBarResult drawTitleBar(const BrowserViewModel& vm, bool maximized,
                                          ActionQueue& actions, WindowRequests& window);
void drawAboutModal(bool& open);

/// Two-row toolbar: actions, then the location field (breadcrumbs or a text
/// input). Keeps the text buffer as ephemeral view state.
class Toolbar {
  public:
    void draw(const BrowserViewModel& vm, ActionQueue& actions);

  private:
    void locationRow(const BrowserViewModel& vm, ActionQueue& actions);

    std::string draft_;
    bool wasEditing_{false};
};
void drawSidebar(const BrowserViewModel& vm, ActionQueue& actions, const Fonts& fonts);
void drawStatusBar(const BrowserViewModel& vm);
void drawErrorBanner(const domain::FsError& error, ActionQueue& actions);

/// The file table keeps a tiny bit of *ephemeral* view state (which keyboard
/// selection it already scrolled to), which is why it is a class.
class FileTable {
  public:
    void draw(const BrowserViewModel& vm, ActionQueue& actions, const Fonts& fonts);

    /// Screen rect of the column header drawn this frame (for its shadow).
    struct Rect {
        ImVec2 min;
        ImVec2 max;
    };
    [[nodiscard]] const std::optional<Rect>& headerRect() const { return headerRect_; }

  private:
    std::optional<Rect> headerRect_;
    std::uint64_t revealedRevision_{0};
};

} // namespace fm::presentation::view
