#pragma once

#include "domain/Ports.hpp"

namespace fm::infrastructure {

/// Adapter: reads directories from the local filesystem with std::filesystem.
class LocalFileSystem final : public domain::FileSystemRepository {
public:
    [[nodiscard]] std::expected<std::vector<domain::FileEntry>, domain::FsError>
    readDirectory(const domain::DirectoryPath& path) const override;
};

} // namespace fm::infrastructure
