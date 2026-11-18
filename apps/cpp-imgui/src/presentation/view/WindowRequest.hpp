#pragma once

#include <cstdint>
#include <vector>

namespace fm::presentation {

/// What the custom window chrome asks the platform window to do. Views emit
/// these next to view-model actions; the application forwards them to the
/// platform layer (presentation never touches GLFW directly).
struct WindowRequest {
    enum class Kind : std::uint8_t { Minimize, ToggleMaximize, Close, BeginMove, BeginResize };
    /// Edge bit flags for `BeginResize`.
    enum Edge : unsigned { Top = 1U, Bottom = 2U, Left = 4U, Right = 8U };

    Kind kind;
    unsigned edges{0};
};

using WindowRequests = std::vector<WindowRequest>;

} // namespace fm::presentation
