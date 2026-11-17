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

    [[nodiscard]] ActionQueue draw(const BrowserViewModel& vm);

  private:
    static void bindShortcuts(ActionQueue& actions);
    static void drawElevation(const view::FileTable::Rect& sidebar,
                              const view::FileTable::Rect& toolbar,
                              const std::optional<view::FileTable::Rect>& header);

    Fonts fonts_;
    view::FileTable table_;
};

} // namespace fm::presentation
