#include "domain/FileEntry.hpp"

#include <algorithm>
#include <cctype>

namespace fm::domain {

bool FileEntry::isSymlink() const noexcept {
    return kind == EntryKind::SymlinkToDirectory || kind == EntryKind::SymlinkToFile;
}

bool FileEntry::isNavigable() const noexcept {
    return kind == EntryKind::Directory || kind == EntryKind::SymlinkToDirectory;
}

std::string FileEntry::extension() const {
    if (isNavigable()) {
        return {};
    }
    auto ext = path.extension().string();
    if (ext.size() <= 1) {
        return {};
    }
    ext.erase(0, 1);
    std::ranges::transform(ext, ext.begin(),
                           [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return ext;
}

} // namespace fm::domain
