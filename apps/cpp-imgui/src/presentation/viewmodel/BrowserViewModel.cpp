#include "presentation/viewmodel/BrowserViewModel.hpp"

#include <algorithm>

namespace fm::presentation {

namespace {

/// Helper to visit a variant with a set of lambdas.
template <class... Ts> struct Overloaded : Ts... {
    using Ts::operator()...;
};

} // namespace

BrowserViewModel::BrowserViewModel(application::BrowseDirectory browse,
                                   const application::ListPlaces& places)
    : loader_(std::move(browse)), history_(places.startLocation()), places_(places()) {
    navigate(Reload{});
}

std::optional<domain::ListingSummary> BrowserViewModel::summary() const {
    if (!listing_) {
        return std::nullopt;
    }
    return listing_->summary(visibility_);
}

std::optional<std::size_t> BrowserViewModel::selectedIndex() const {
    if (!selected_) {
        return std::nullopt;
    }
    const auto it = std::ranges::find_if(visible_, [&](const auto* e) { return e->path == *selected_; });
    if (it == visible_.end()) {
        return std::nullopt;
    }
    return static_cast<std::size_t>(std::distance(visible_.begin(), it));
}

void BrowserViewModel::dispatch(const Action& action) {
    std::visit(Overloaded{
                   [this](const action::GoBack&) { navigate(Back{}); },
                   [this](const action::GoForward&) { navigate(Forward{}); },
                   [this](const action::GoUp&) { navigate(Up{}); },
                   [this](const action::Refresh&) { navigate(Reload{}); },
                   [this](const action::Open& a) { navigate(Visit{a.path}); },
                   [this](const action::ToggleHidden&) {
                       visibility_ = domain::toggled(visibility_);
                       rebuildVisible();
                   },
                   [this](const action::DismissError&) { error_.reset(); },
                   [this](const action::Select& a) { selected_ = a.path; },
                   [this](const action::Activate& a) { activate(a.path); },
                   [this](const action::ActivateSelection&) {
                       if (selected_) {
                           activate(*selected_);
                       }
                   },
                   [this](const action::MoveSelection& a) { moveSelection(a.delta); },
               },
               action);
}

void BrowserViewModel::tick() {
    auto completed = loader_.poll();
    if (!completed || completed->ticket != ticket_ || !pending_) {
        return; // Nothing new, or a superseded navigation.
    }
    loading_ = false;
    if (completed->result) {
        commit(*pending_, completed->result->path());
        listing_ = std::move(*completed->result);
        selected_.reset();
        error_.reset();
        rebuildVisible();
    } else {
        error_ = completed->result.error();
    }
    pending_.reset();
}

void BrowserViewModel::navigate(Navigation navigation) {
    const auto destination = std::visit(
        Overloaded{
            [](const Visit& v) -> std::optional<domain::DirectoryPath> { return v.destination; },
            [this](const Back&) { return history_.peekBack(); },
            [this](const Forward&) { return history_.peekForward(); },
            [this](const Up&) { return history_.current().parent(); },
            [this](const Reload&) -> std::optional<domain::DirectoryPath> { return history_.current(); },
        },
        navigation);
    if (!destination) {
        return;
    }
    loading_ = true;
    pending_ = std::move(navigation);
    loader_.request(++ticket_, *destination);
}

void BrowserViewModel::commit(const Navigation& navigation, const domain::DirectoryPath& destination) {
    std::visit(Overloaded{
                   [&](const Visit&) { history_.visit(destination); },
                   [&](const Up&) { history_.visit(destination); },
                   [&](const Back&) { history_.goBack(); },
                   [&](const Forward&) { history_.goForward(); },
                   [](const Reload&) {},
               },
               navigation);
}

void BrowserViewModel::activate(const std::filesystem::path& path) {
    const auto it = std::ranges::find_if(visible_, [&](const auto* e) { return e->path == path; });
    if (it == visible_.end()) {
        return;
    }
    if (!(*it)->isNavigable()) {
        selected_ = path; // Opening files is out of scope for this draft.
        return;
    }
    if (auto destination = domain::DirectoryPath::from(path)) {
        navigate(Visit{std::move(*destination)});
    }
}

void BrowserViewModel::moveSelection(int delta) {
    if (visible_.empty()) {
        return;
    }
    const auto last = static_cast<long>(visible_.size()) - 1;
    const auto current = selectedIndex();
    const long next = current ? std::clamp(static_cast<long>(*current) + delta, 0L, last) : 0L;
    selected_ = visible_.at(static_cast<std::size_t>(next))->path;
    ++revealRevision_;
}

void BrowserViewModel::rebuildVisible() {
    visible_ = listing_ ? listing_->visible(visibility_) : std::vector<const domain::FileEntry*>{};
}

} // namespace fm::presentation
