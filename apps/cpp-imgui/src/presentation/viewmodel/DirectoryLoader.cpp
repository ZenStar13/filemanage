#include "presentation/viewmodel/DirectoryLoader.hpp"

#include <thread>
#include <utility>

namespace fm::presentation {

DirectoryLoader::DirectoryLoader(application::BrowseDirectory browse)
    : browse_(std::move(browse)) {}

void DirectoryLoader::request(std::uint64_t ticket, domain::DirectoryPath path) {
    // The worker only captures shared state, so it may safely outlive us
    // (e.g. a slow network mount while the window is closing).
    std::thread([browse = browse_, inbox = inbox_, ticket, path = std::move(path)] {
        auto result = browse(path);
        const std::scoped_lock lock{inbox->mutex};
        if (!inbox->latest || inbox->latest->ticket < ticket) {
            inbox->latest = Completed{.ticket = ticket, .result = std::move(result)};
        }
    }).detach();
}

std::optional<DirectoryLoader::Completed> DirectoryLoader::poll() {
    const std::scoped_lock lock{inbox_->mutex};
    return std::exchange(inbox_->latest, std::nullopt);
}

} // namespace fm::presentation
