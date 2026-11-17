#include "application/BrowseDirectory.hpp"
#include "infrastructure/LocalFileSystem.hpp"

#include <doctest/doctest.h>
#include <fstream>
#include <memory>

using namespace fm;

namespace {

class FakeFileSystem final : public domain::FileSystemRepository {
  public:
    [[nodiscard]] std::expected<std::vector<domain::FileEntry>, domain::FsError>
    readDirectory(const domain::DirectoryPath& path) const override {
        if (path.string() == "/locked") {
            return std::unexpected(domain::FsError{.kind = domain::FsError::Kind::PermissionDenied,
                                                   .path = path.value(),
                                                   .detail = {}});
        }
        return std::vector<domain::FileEntry>{
            {.name = "z.txt",
             .path = "/z.txt",
             .kind = domain::EntryKind::File,
             .size = 1,
             .modified = {}},
            {.name = "dir",
             .path = "/dir",
             .kind = domain::EntryKind::Directory,
             .size = {},
             .modified = {}},
        };
    }
};

} // namespace

TEST_CASE("BrowseDirectory returns a sorted listing or a domain error") {
    const application::BrowseDirectory browse{std::make_shared<FakeFileSystem>()};
    const auto listing = browse(domain::DirectoryPath::root());
    REQUIRE(listing.has_value());
    CHECK(listing->entries().front().name == "dir");

    const auto locked = browse(*domain::DirectoryPath::from("/locked"));
    REQUIRE_FALSE(locked.has_value());
    CHECK(locked.error().kind == domain::FsError::Kind::PermissionDenied);
}

TEST_CASE("LocalFileSystem maps OS errors and reads real directories") {
    const infrastructure::LocalFileSystem fs;
    const auto missing = fs.readDirectory(*domain::DirectoryPath::from("/definitely/not/here/42"));
    REQUIRE_FALSE(missing.has_value());
    CHECK(missing.error().kind == domain::FsError::Kind::NotFound);

    const auto dir = std::filesystem::temp_directory_path() / "fm-imgui-test";
    std::filesystem::create_directories(dir / "sub");
    std::ofstream{dir / "file.txt"} << "hello";
    const auto entries = fs.readDirectory(*domain::DirectoryPath::from(dir));
    std::filesystem::remove_all(dir);
    REQUIRE(entries.has_value());
    CHECK(entries->size() == 2);
}
