#include "domain/DirectoryListing.hpp"
#include "domain/DirectoryPath.hpp"
#include "domain/NavigationHistory.hpp"

#include <doctest/doctest.h>

using namespace fm::domain;

namespace {

DirectoryPath path(const char* raw) { return *DirectoryPath::from(raw); }

FileEntry entry(const std::string& name, EntryKind kind) {
    return {.name = name, .path = "/t/" + name, .kind = kind, .size = 10, .modified = std::nullopt};
}

} // namespace

TEST_CASE("DirectoryPath enforces absolute paths and builds breadcrumbs") {
    CHECK_FALSE(DirectoryPath::from("relative/dir").has_value());
    const auto segments = path("/home/user/docs").segments();
    REQUIRE(segments.size() == 4);
    CHECK(segments[0].label == "/");
    CHECK(segments[3].label == "docs");
    CHECK(segments[1].path == path("/home"));
    CHECK_FALSE(DirectoryPath::root().parent().has_value());
    CHECK(path("/home/user/").name() == "user");
}

TEST_CASE("NavigationHistory supports back/forward and clears forward on visit") {
    NavigationHistory history{path("/a")};
    history.visit(path("/a/b"));
    history.visit(path("/a/b/c"));
    CHECK(history.goBack());
    CHECK(history.current() == path("/a/b"));
    CHECK(history.goForward());
    CHECK(history.current() == path("/a/b/c"));

    history.goBack();
    history.visit(path("/x"));
    CHECK_FALSE(history.canGoForward());

    NavigationHistory same{path("/a")};
    same.visit(path("/a"));
    CHECK_FALSE(same.canGoBack());
}

TEST_CASE("DirectoryListing sorts folders first and filters hidden entries") {
    const DirectoryListing listing{path("/t"),
                                   {entry("b.txt", EntryKind::File), entry("Zeta", EntryKind::Directory),
                                    entry("A.txt", EntryKind::File), entry("alpha", EntryKind::Directory),
                                    entry(".env", EntryKind::File)}};
    const auto visible = listing.visible(Visibility::HideHidden);
    REQUIRE(visible.size() == 4);
    CHECK(visible[0]->name == "alpha");
    CHECK(visible[1]->name == "Zeta");
    CHECK(visible[2]->name == "A.txt");
    CHECK(listing.visible(Visibility::ShowHidden).size() == 5);

    const auto summary = listing.summary(Visibility::HideHidden);
    CHECK(summary.folders == 2);
    CHECK(summary.files == 2);
    CHECK(summary.hidden == 1);
    CHECK(summary.totalBytes == 20);
}
