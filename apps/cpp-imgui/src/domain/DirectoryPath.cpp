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

DirectoryPath DirectoryPath::root() {
    return DirectoryPath{"/"};
}

std::optional<DirectoryPath> DirectoryPath::resolveUserInput(std::string_view input,
                                                             const DirectoryPath& current,
                                                             const DirectoryPath& home) {
    const auto first = input.find_first_not_of(" \t");
    if (first == std::string_view::npos) {
        return std::nullopt;
    }
    const auto text = input.substr(first, input.find_last_not_of(" \t") - first + 1);
    std::filesystem::path raw;
    if (text == "~") {
        raw = home.value();
    } else if (text.starts_with("~/")) {
        raw = home.value() / std::filesystem::path{text.substr(2)};
    } else if (text.starts_with('/')) {
        raw = std::filesystem::path{text};
    } else {
        raw = current.value() / std::filesystem::path{text};
    }
    std::filesystem::path normal{"/"};
    for (const auto& part : raw.relative_path()) {
        if (part == "..") {
            normal = normal.has_relative_path() ? normal.parent_path() : normal;
        } else if (part != "." && !part.empty()) {
            normal /= part;
        }
    }
    return DirectoryPath{std::move(normal)};
}

std::string DirectoryPath::name() const {
    return isRoot() ? path_.string() : path_.filename().string();
}

bool DirectoryPath::isRoot() const {
    return path_ == path_.root_path();
}

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
