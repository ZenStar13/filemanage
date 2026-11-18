#pragma once

#include "application/BrowseDirectory.hpp"
#include "application/ListPlaces.hpp"
#include "domain/DirectoryListing.hpp"
#include "domain/NavigationHistory.hpp"
#include "presentation/viewmodel/Action.hpp"
#include "presentation/viewmodel/DirectoryLoader.hpp"

#include <cstdint>
#include <optional>
#include <variant>

namespace fm::presentation {

/// View model of the browser screen.
///
/// Immediate-mode MVVM: views read state through const getters every frame
/// and emit `Action`s; `dispatch` is the single entry point for mutations and
/// `tick` integrates asynchronous results. No ImGui code lives here.
class BrowserViewModel {
  public:
    BrowserViewModel(application::BrowseDirectory browse, const application::ListPlaces& places);

    // ---- State ------------------------------------------------------------
    [[nodiscard]] const domain::DirectoryPath& currentPath() const { return history_.current(); }
    [[nodiscard]] const std::vector<domain::Place>& places() const { return places_; }
    [[nodiscard]] const std::vector<const domain::FileEntry*>& entries() const { return visible_; }
    [[nodiscard]] std::optional<domain::ListingSummary> summary() const;
    [[nodiscard]] const std::optional<std::filesystem::path>& selected() const { return selected_; }
    [[nodiscard]] std::optional<std::size_t> selectedIndex() const;
    [[nodiscard]] const std::optional<domain::FsError>& error() const { return error_; }
    [[nodiscard]] bool canGoBack() const { return history_.canGoBack(); }
    [[nodiscard]] bool canGoForward() const { return history_.canGoForward(); }
    [[nodiscard]] bool canGoUp() const { return history_.canGoUp(); }
    [[nodiscard]] bool showsHidden() const { return visibility_ == domain::Visibility::ShowHidden; }
    [[nodiscard]] bool isLoading() const { return loading_; }
    /// Whether the location row shows a text input instead of breadcrumbs.
    [[nodiscard]] bool isEditingLocation() const { return editingLocation_; }
    /// Bumped when the selection moves via keyboard, so views can reveal it.
    [[nodiscard]] std::uint64_t revealRevision() const { return revealRevision_; }

    // ---- Behaviour --------------------------------------------------------
    void dispatch(const Action& action);
    void tick();

  private:
    struct Visit {
        domain::DirectoryPath destination;
    };
    struct Back {};
    struct Forward {};
    struct Up {};
    struct Reload {};
    using Navigation = std::variant<Visit, Back, Forward, Up, Reload>;

    void navigate(Navigation navigation);
    void commit(const Navigation& navigation, const domain::DirectoryPath& destination);
    void activate(const std::filesystem::path& path);
    void moveSelection(int delta);
    void rebuildVisible();

    DirectoryLoader loader_;
    domain::NavigationHistory history_;
    domain::DirectoryPath home_;
    bool editingLocation_{false};
    std::vector<domain::Place> places_;
    std::optional<domain::DirectoryListing> listing_;
    std::vector<const domain::FileEntry*> visible_;
    domain::Visibility visibility_{domain::Visibility::HideHidden};
    std::optional<std::filesystem::path> selected_;
    std::optional<domain::FsError> error_;
    bool loading_{false};
    std::uint64_t ticket_{0};
    std::optional<Navigation> pending_;
    std::uint64_t revealRevision_{0};
};

} // namespace fm::presentation
