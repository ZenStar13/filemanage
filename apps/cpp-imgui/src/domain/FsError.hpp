#pragma once

#include <cstdint>
#include <filesystem>
#include <string>

namespace fm::domain {

/// Domain failure when reading the filesystem. Adapters translate OS errors
/// into these so upper layers never see `std::error_code` / errno.
struct FsError {
    enum class Kind : std::uint8_t { NotFound, PermissionDenied, NotADirectory, Io };

    Kind kind{Kind::Io};
    std::filesystem::path path;
    std::string detail; ///< OS message, for `Io` only

    [[nodiscard]] std::string message() const {
        const auto p = path.string();
        switch (kind) {
        case Kind::NotFound:
            return "“" + p + "” does not exist";
        case Kind::PermissionDenied:
            return "You don't have permission to open “" + p + "”";
        case Kind::NotADirectory:
            return "“" + p + "” is not a folder";
        case Kind::Io:
            break;
        }
        return "Could not read “" + p + "”: " + detail;
    }
};

} // namespace fm::domain
