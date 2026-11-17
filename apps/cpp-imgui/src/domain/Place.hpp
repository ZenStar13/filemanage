#pragma once

#include "domain/DirectoryPath.hpp"

#include <cstdint>
#include <string>

namespace fm::domain {

enum class PlaceKind : std::uint8_t { Home, Desktop, Documents, Downloads, Pictures, Music, Videos, Root };

/// Value object: a named shortcut shown in the sidebar.
struct Place {
    PlaceKind kind;
    std::string label;
    DirectoryPath path;
};

} // namespace fm::domain
