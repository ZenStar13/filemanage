#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace fm::domain {

struct PathSegment;

/// Value object: an absolute, normalised directory location.
/// The invariant (absolute path) is enforced by the only factory, `from`.
class DirectoryPath {
  public:
    [[nodiscard]] static std::optional<DirectoryPath> from(const std::filesystem::path& raw);
    [[nodiscard]] static DirectoryPath root();

    [[nodiscard]] const std::filesystem::path& value() const noexcept { return path_; }
    [[nodiscard]] std::string string() const { return path_.string(); }
    [[nodiscard]] std::string name() const;
    [[nodiscard]] bool isRoot() const;
    [[nodiscard]] std::optional<DirectoryPath> parent() const;
    [[nodiscard]] std::vector<PathSegment> segments() const;

    friend bool operator==(const DirectoryPath&, const DirectoryPath&) = default;

  private:
    explicit DirectoryPath(std::filesystem::path path) : path_(std::move(path)) {}

    std::filesystem::path path_;
};

/// One clickable segment of a breadcrumb trail.
struct PathSegment {
    std::string label;
    DirectoryPath path;
};

} // namespace fm::domain
