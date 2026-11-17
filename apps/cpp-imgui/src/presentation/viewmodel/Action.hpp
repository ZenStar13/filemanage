#pragma once

#include "domain/DirectoryPath.hpp"

#include <filesystem>
#include <variant>
#include <vector>

/// User intents emitted by views. Views never mutate state: they append
/// actions, and the view model applies them after the frame is built.
namespace fm::presentation::action {

struct GoBack {};
struct GoForward {};
struct GoUp {};
struct Refresh {};
struct ToggleHidden {};
struct DismissError {};
struct ActivateSelection {};
struct MoveSelection {
    int delta;
};
struct Open {
    domain::DirectoryPath path;
};
struct Select {
    std::filesystem::path path;
};
struct Activate {
    std::filesystem::path path;
};

} // namespace fm::presentation::action

namespace fm::presentation {

using Action = std::variant<action::GoBack, action::GoForward, action::GoUp, action::Refresh,
                            action::ToggleHidden, action::DismissError, action::ActivateSelection,
                            action::MoveSelection, action::Open, action::Select, action::Activate>;

using ActionQueue = std::vector<Action>;

} // namespace fm::presentation
