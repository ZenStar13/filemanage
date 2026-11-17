#include "application/BrowseDirectory.hpp"

namespace fm::application {

BrowseDirectory::BrowseDirectory(std::shared_ptr<const domain::FileSystemRepository> repository)
    : repository_(std::move(repository)) {}

std::expected<domain::DirectoryListing, domain::FsError>
BrowseDirectory::operator()(const domain::DirectoryPath& path) const {
    return repository_->readDirectory(path).transform([&](std::vector<domain::FileEntry> entries) {
        return domain::DirectoryListing{path, std::move(entries)};
    });
}

} // namespace fm::application
