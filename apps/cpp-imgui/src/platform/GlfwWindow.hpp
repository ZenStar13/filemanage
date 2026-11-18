#pragma once

#include <cstdint>
#include <string>

struct GLFWwindow;

namespace fm::platform {

/// RAII host for a GLFW window, its OpenGL 3 context and the Dear ImGui
/// context + platform/renderer backends. Non-copyable, non-movable.
class GlfwWindow {
  public:
    struct Options {
        std::string title;
        int width;
        int height;
    };

    explicit GlfwWindow(const Options& options);
    ~GlfwWindow();
    GlfwWindow(const GlfwWindow&) = delete;
    GlfwWindow& operator=(const GlfwWindow&) = delete;
    GlfwWindow(GlfwWindow&&) = delete;
    GlfwWindow& operator=(GlfwWindow&&) = delete;

    [[nodiscard]] bool shouldClose() const;
    [[nodiscard]] float contentScale() const { return scale_; }
    /// Blocks until input arrives or `timeoutSeconds` elapse: a file manager
    /// does not need to burn CPU re-rendering at 60 FPS while idle.
    /// Returns true when woken up by an event rather than the timeout.
    [[nodiscard]] bool waitEvents(double timeoutSeconds) const;
    void beginFrame() const;
    void endFrame() const;

    // ---- Client-side decorations ------------------------------------------
    // The window is undecorated; the UI draws its own title bar and calls
    // these. GLFW has no API to hand a move/resize to the window manager, so
    // they are done manually from pointer deltas (works on X11; Wayland does
    // not let clients position their own windows).

    /// Edge bit flags for `beginResize`.
    enum Edge : unsigned { Top = 1U, Bottom = 2U, Left = 4U, Right = 8U };

    void minimize() const;
    void toggleMaximize() const;
    [[nodiscard]] bool isMaximized() const;
    void requestClose() const;
    void beginMove();
    void beginResize(unsigned edges);
    /// Applies an ongoing move/resize; call once per frame.
    void updateInteraction();
    [[nodiscard]] bool isInteracting() const { return interaction_ != Interaction::None; }

  private:
    enum class Interaction : std::uint8_t { None, Move, Resize };

    void screenCursor(double& x, double& y) const;

    GLFWwindow* window_{nullptr};
    float scale_{1.0F};
    Interaction interaction_{Interaction::None};
    unsigned edges_{0};
    double anchorX_{0};
    double anchorY_{0};
    int startX_{0};
    int startY_{0};
    int startWidth_{0};
    int startHeight_{0};
};

} // namespace fm::platform
