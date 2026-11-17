#include "domain/DirectoryListing.hpp"

#include <algorithm>
#include <cctype>

namespace fm::domain {

namespace {

bool lessCaseInsensitive(const std::string& a, const std::string& b) {
    return std::ranges::lexicographical_compare(
        a, b, [](unsigned char x, unsigned char y) { return std::tolower(x) < std::tolower(y); });
}

/// Domain rule: folders first, then case-insensitive name, then exact name.
bool browseOrder(const FileEntry& a, const FileEntry& b) {
    if (a.isNavigable() != b.isNavigable()) {
        return a.isNavigable();
    }
    if (lessCaseInsensitive(a.name, b.name)) {
        return true;
    }
    if (lessCaseInsensitive(b.name, a.name)) {
        return false;
    }
    return a.name < b.name;
}

} // namespace

DirectoryListing::DirectoryListing(DirectoryPath path, std::vector<FileEntry> entries)
    : path_(std::move(path)), entries_(std::move(entries)) {
    std::ranges::sort(entries_, browseOrder);
}

std::vector<const FileEntry*> DirectoryListing::visible(Visibility visibility) const {
    std::vector<const FileEntry*> result;
    result.reserve(entries_.size());
    for (const auto& entry : entries_) {
        if (visibility == Visibility::ShowHidden || !entry.isHidden()) {
            result.push_back(&entry);
        }
    }
    return result;
}

ListingSummary DirectoryListing::summary(Visibility visibility) const {
    ListingSummary summary{};
    summary.hidden = static_cast<std::size_t>(
        std::ranges::count_if(entries_, [](const FileEntry& e) { return e.isHidden(); }));
    for (const auto* entry : visible(visibility)) {
        if (entry->isNavigable()) {
            ++summary.folders;
        } else {
            ++summary.files;
            summary.totalBytes += entry->size.value_or(0);
        }
    }
    return summary;
}

} // namespace fm::domain
