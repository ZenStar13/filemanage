#include "domain/NavigationHistory.hpp"

#include <utility>

namespace fm::domain {

std::optional<DirectoryPath> NavigationHistory::peekBack() const {
    return back_.empty() ? std::nullopt : std::optional{back_.back()};
}

std::optional<DirectoryPath> NavigationHistory::peekForward() const {
    return forward_.empty() ? std::nullopt : std::optional{forward_.back()};
}

void NavigationHistory::visit(DirectoryPath destination) {
    if (destination == current_) {
        return;
    }
    back_.push_back(std::exchange(current_, std::move(destination)));
    forward_.clear();
}

bool NavigationHistory::goBack() {
    if (back_.empty()) {
        return false;
    }
    forward_.push_back(std::exchange(current_, std::move(back_.back())));
    back_.pop_back();
    return true;
}

bool NavigationHistory::goForward() {
    if (forward_.empty()) {
        return false;
    }
    back_.push_back(std::exchange(current_, std::move(forward_.back())));
    forward_.pop_back();
    return true;
}

} // namespace fm::domain
