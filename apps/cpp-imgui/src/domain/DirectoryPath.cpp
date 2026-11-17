#include "domain/DirectoryPath.hpp"

namespace fm::domain {

std::optional<DirectoryPath> DirectoryPath::from(const std::filesystem::path& raw) {
    if (!raw.is_absolute()) {
        return std::nullopt;
    }
    auto normal = raw.lexically_normal();
    // "/a/b/" normalises to "/a/b/"; drop the trailing separator (except root).
    if (normal.has_relative_path() && !normal.has_filename()) {
        normal = normal.parent_path();
    }
    return DirectoryPath{std::move(normal)};
}

DirectoryPath DirectoryPath::root() { return DirectoryPath{"/"}; }

std::string DirectoryPath::name() const {
    return isRoot() ? path_.string() : path_.filename().string();
}

bool DirectoryPath::isRoot() const { return path_ == path_.root_path(); }

std::optional<DirectoryPath> DirectoryPath::parent() const {
    if (isRoot()) {
        return std::nullopt;
    }
    return DirectoryPath{path_.parent_path()};
}

std::vector<PathSegment> DirectoryPath::segments() const {
    std::vector<PathSegment> result;
    std::filesystem::path acc;
    for (const auto& part : path_) {
        acc /= part;
        result.push_back(PathSegment{.label = part.string(), .path = DirectoryPath{acc}});
    }
    return result;
}

} // namespace fm::domain
