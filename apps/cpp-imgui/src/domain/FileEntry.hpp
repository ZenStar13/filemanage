#pragma once

#include <chrono>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>

namespace fm::domain {

/// Classification of a directory entry for browsing purposes.
enum class EntryKind : std::uint8_t {
    Directory,
    File,
    SymlinkToDirectory,
    SymlinkToFile,
    Other,
};

/// Entity: an item inside a directory. Identity is its absolute path.
struct FileEntry {
    std::string name;
    std::filesystem::path path;
    EntryKind kind{EntryKind::Other};
    std::optional<std::uintmax_t> size;                           ///< regular files only
    std::optional<std::chrono::system_clock::time_point> modified;

    /// Unix convention: dot-files are hidden.
    [[nodiscard]] bool isHidden() const noexcept { return name.starts_with('.'); }
    [[nodiscard]] bool isSymlink() const noexcept;
    /// Whether the user can navigate into this entry.
    [[nodiscard]] bool isNavigable() const noexcept;
    /// Lower-cased extension without the dot (empty for folders / none).
    [[nodiscard]] std::string extension() const;
};

} // namespace fm::domain
