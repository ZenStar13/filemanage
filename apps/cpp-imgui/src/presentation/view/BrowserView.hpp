#pragma once

#include "presentation/theme/Theme.hpp"
#include "presentation/view/Views.hpp"
#include "presentation/viewmodel/Action.hpp"
#include "presentation/viewmodel/BrowserViewModel.hpp"

namespace fm::presentation {

/// Root view: lays out sidebar, toolbar, table and status bar and binds
/// global keyboard shortcuts. Returns the actions gathered this frame.
class BrowserView {
  public:
    explicit BrowserView(Fonts fonts) : fonts_(fonts) {}

    /// Everything the user asked for this frame.
    struct Output {
        ActionQueue actions;
        WindowRequests window;
    };

    /// `maximized` drives the maximise/restore glyph in the title bar.
    [[nodiscard]] Output draw(const BrowserViewModel& vm, bool maximized);

  private:
    static void bindShortcuts(ActionQueue& actions, WindowRequests& window);
    static void resizeEdges(WindowRequests& window);
    static void drawElevation(const view::FileTable::Rect& title,
                              const view::FileTable::Rect& sidebar,
                              const view::FileTable::Rect& toolbar,
                              const std::optional<view::FileTable::Rect>& header);

    Fonts fonts_;
    view::FileTable table_;
    view::Toolbar toolbar_;
    bool aboutOpen_{false};
};

} // namespace fm::presentation
