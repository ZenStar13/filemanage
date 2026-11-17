// Composition root: builds the adapters, wires them into the use cases and
// hands those to the application. The only place that knows concrete types.

#include "app/Application.hpp"
#include "infrastructure/LocalFileSystem.hpp"
#include "infrastructure/XdgPlaces.hpp"

#include <cstdio>
#include <exception>
#include <filesystem>
#include <memory>

namespace {

/// Assets are copied next to the executable by the build.
std::filesystem::path assetDirectory() {
    std::error_code ec;
    const auto exe = std::filesystem::read_symlink("/proc/self/exe", ec);
    return (ec ? std::filesystem::current_path() : exe.parent_path()) / "assets";
}

} // namespace

int main() {
    try {
        fm::app::Services services{
            .browse = fm::application::BrowseDirectory{std::make_shared<fm::infrastructure::LocalFileSystem>()},
            .places = fm::application::ListPlaces{std::make_shared<fm::infrastructure::XdgPlaces>()},
        };
        fm::app::Application app{std::move(services), assetDirectory()};
        return app.run();
    } catch (const std::exception& e) {
        std::fprintf(stderr, "fatal: %s\n", e.what()); // NOLINT(cppcoreguidelines-pro-type-vararg)
        return 1;
    }
}
