#pragma once

#include "domain/DirectoryPath.hpp"
#include "domain/FileEntry.hpp"

#include <cstdint>
#include <vector>

namespace fm::domain {

/// Whether hidden (dot) entries are shown.
enum class Visibility : std::uint8_t { HideHidden, ShowHidden };

[[nodiscard]] constexpr Visibility toggled(Visibility v) noexcept {
    return v == Visibility::HideHidden ? Visibility::ShowHidden : Visibility::HideHidden;
}

/// Counts for the status bar.
struct ListingSummary {
    std::size_t folders{};
    std::size_t files{};
    std::size_t hidden{};
    std::uintmax_t totalBytes{};
};

/// Aggregate: the content of one directory, kept in canonical browse order
/// (folders first, then case-insensitive name). The ordering is a domain rule.
class DirectoryListing {
  public:
    DirectoryListing(DirectoryPath path, std::vector<FileEntry> entries);

    [[nodiscard]] const DirectoryPath& path() const noexcept { return path_; }
    [[nodiscard]] const std::vector<FileEntry>& entries() const noexcept { return entries_; }
    [[nodiscard]] std::vector<const FileEntry*> visible(Visibility visibility) const;
    [[nodiscard]] ListingSummary summary(Visibility visibility) const;

  private:
    DirectoryPath path_;
    std::vector<FileEntry> entries_;
};

} // namespace fm::domain
