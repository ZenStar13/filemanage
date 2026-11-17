#pragma once

#include "presentation/theme/Theme.hpp"
#include "presentation/viewmodel/Action.hpp"
#include "presentation/viewmodel/BrowserViewModel.hpp"

#include <cstdint>
#include <imgui.h>
#include <optional>

/// Sub-views of the browser screen. Each is a pure function of the (const)
/// view model that records user intents into the action queue.
namespace fm::presentation::view {

void drawToolbar(const BrowserViewModel& vm, ActionQueue& actions);
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
