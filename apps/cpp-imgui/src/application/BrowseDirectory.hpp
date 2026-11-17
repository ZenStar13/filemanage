#pragma once

#include "domain/DirectoryListing.hpp"
#include "domain/Ports.hpp"

#include <expected>
#include <memory>

namespace fm::application {

/// Use case: read a directory and return its listing in browse order.
/// Cheap to copy (shares the repository), safe to run on worker threads.
class BrowseDirectory {
public:
    explicit BrowseDirectory(std::shared_ptr<const domain::FileSystemRepository> repository);

    [[nodiscard]] std::expected<domain::DirectoryListing, domain::FsError>
    operator()(const domain::DirectoryPath& path) const;

private:
    std::shared_ptr<const domain::FileSystemRepository> repository_;
};

} // namespace fm::application
