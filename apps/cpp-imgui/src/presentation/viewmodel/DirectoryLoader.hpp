#pragma once

#include "application/BrowseDirectory.hpp"

#include <cstdint>
#include <expected>
#include <memory>
#include <mutex>
#include <optional>

namespace fm::presentation {

/// Runs `BrowseDirectory` on a worker thread so the render loop never blocks
/// on disk I/O. Every request carries a ticket; only the newest result is
/// kept, so stale responses from superseded navigations are dropped.
class DirectoryLoader {
public:
    using Result = std::expected<domain::DirectoryListing, domain::FsError>;

    struct Completed {
        std::uint64_t ticket;
        Result result;
    };

    explicit DirectoryLoader(application::BrowseDirectory browse);

    void request(std::uint64_t ticket, domain::DirectoryPath path);
    /// Non-blocking: returns the latest completed load, if any.
    [[nodiscard]] std::optional<Completed> poll();

private:
    struct Inbox {
        std::mutex mutex;
        std::optional<Completed> latest;
    };

    application::BrowseDirectory browse_;
    std::shared_ptr<Inbox> inbox_ = std::make_shared<Inbox>();
};

} // namespace fm::presentation
