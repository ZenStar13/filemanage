#pragma once

#include "domain/DirectoryListing.hpp"
#include "domain/FileEntry.hpp"

#include <string>

/// Human-friendly formatting of domain values for display.
namespace fm::presentation::format {

[[nodiscard]] std::string size(std::uintmax_t bytes);
[[nodiscard]] std::string entrySize(const domain::FileEntry& entry);
[[nodiscard]] std::string modified(const domain::FileEntry& entry);
[[nodiscard]] std::string kind(const domain::FileEntry& entry);
[[nodiscard]] std::string summary(const domain::ListingSummary& summary, bool showingHidden);

} // namespace fm::presentation::format
