#include "infrastructure/LocalFileSystem.hpp"

#include <system_error>

namespace fm::infrastructure {

namespace fs = std::filesystem;
using domain::EntryKind;
using domain::FsError;

namespace {

FsError toDomainError(const fs::path& path, const std::error_code& ec) {
    using Kind = FsError::Kind;
    if (ec == std::errc::no_such_file_or_directory) {
        return {.kind = Kind::NotFound, .path = path, .detail = {}};
    }
    if (ec == std::errc::permission_denied || ec == std::errc::operation_not_permitted) {
        return {.kind = Kind::PermissionDenied, .path = path, .detail = {}};
    }
    if (ec == std::errc::not_a_directory) {
        return {.kind = Kind::NotADirectory, .path = path, .detail = {}};
    }
    return {.kind = Kind::Io, .path = path, .detail = ec.message()};
}

domain::FileEntry toEntry(const fs::directory_entry& entry) {
    std::error_code ec;
    domain::FileEntry result{
        .name = entry.path().filename().string(),
        .path = entry.path(),
        .kind = EntryKind::Other,
        .size = std::nullopt,
        .modified = std::nullopt,
    };

    // symlink_status does not follow links; status does (to learn the target).
    if (entry.is_symlink(ec)) {
        result.kind =
            entry.is_directory(ec) ? EntryKind::SymlinkToDirectory : EntryKind::SymlinkToFile;
    } else if (entry.is_directory(ec)) {
        result.kind = EntryKind::Directory;
    } else if (entry.is_regular_file(ec)) {
        result.kind = EntryKind::File;
        if (const auto size = entry.file_size(ec); !ec) {
            result.size = size;
        }
    }

    if (const auto time = entry.last_write_time(ec); !ec) {
        result.modified = std::chrono::clock_cast<std::chrono::system_clock>(time);
    }
    return result;
}

} // namespace

std::expected<std::vector<domain::FileEntry>, FsError>
LocalFileSystem::readDirectory(const domain::DirectoryPath& path) const {
    std::error_code ec;
    fs::directory_iterator it{path.value(), fs::directory_options::none, ec};
    if (ec) {
        return std::unexpected(toDomainError(path.value(), ec));
    }

    std::vector<domain::FileEntry> entries;
    // Entries failing mid-iteration are skipped instead of failing the list.
    for (const fs::directory_iterator end; it != end; it.increment(ec)) {
        if (ec) {
            ec.clear();
            continue;
        }
        entries.push_back(toEntry(*it));
    }
    return entries;
}

} // namespace fm::infrastructure
