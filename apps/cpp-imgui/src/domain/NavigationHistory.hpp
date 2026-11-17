#pragma once

#include "domain/DirectoryPath.hpp"

#include <optional>
#include <vector>

namespace fm::domain {

/// Aggregate root of a browsing session: current location + back/forward
/// stacks. Navigation is two-phase: peek a destination, load it, and only
/// commit on success, so failed loads never corrupt history.
class NavigationHistory {
public:
    explicit NavigationHistory(DirectoryPath start) : current_(std::move(start)) {}

    [[nodiscard]] const DirectoryPath& current() const noexcept { return current_; }
    [[nodiscard]] bool canGoBack() const noexcept { return !back_.empty(); }
    [[nodiscard]] bool canGoForward() const noexcept { return !forward_.empty(); }
    [[nodiscard]] bool canGoUp() const { return !current_.isRoot(); }
    [[nodiscard]] std::optional<DirectoryPath> peekBack() const;
    [[nodiscard]] std::optional<DirectoryPath> peekForward() const;

    void visit(DirectoryPath destination);
    bool goBack();
    bool goForward();

private:
    DirectoryPath current_;
    std::vector<DirectoryPath> back_;
    std::vector<DirectoryPath> forward_;
};

} // namespace fm::domain
