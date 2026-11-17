#pragma once

#include "domain/DirectoryPath.hpp"
#include "domain/FileEntry.hpp"
#include "domain/FsError.hpp"
#include "domain/Place.hpp"

#include <expected>
#include <vector>

namespace fm::domain {

/// Port: read access to a hierarchical filesystem.
class FileSystemRepository {
public:
    FileSystemRepository() = default;
    FileSystemRepository(const FileSystemRepository&) = delete;
    FileSystemRepository& operator=(const FileSystemRepository&) = delete;
    FileSystemRepository(FileSystemRepository&&) = delete;
    FileSystemRepository& operator=(FileSystemRepository&&) = delete;
    virtual ~FileSystemRepository() = default;

    /// Immediate children of `path` (unsorted, unfiltered). Must be thread-safe.
    [[nodiscard]] virtual std::expected<std::vector<FileEntry>, FsError>
    readDirectory(const DirectoryPath& path) const = 0;
};

/// Port: the user's well-known locations.
class PlacesProvider {
public:
    PlacesProvider() = default;
    PlacesProvider(const PlacesProvider&) = delete;
    PlacesProvider& operator=(const PlacesProvider&) = delete;
    PlacesProvider(PlacesProvider&&) = delete;
    PlacesProvider& operator=(PlacesProvider&&) = delete;
    virtual ~PlacesProvider() = default;

    [[nodiscard]] virtual DirectoryPath home() const = 0;
    [[nodiscard]] virtual std::vector<Place> places() const = 0;
};

} // namespace fm::domain
