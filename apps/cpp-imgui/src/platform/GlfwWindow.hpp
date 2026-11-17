#pragma once

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

  private:
    GLFWwindow* window_{nullptr};
    float scale_{1.0F};
};

} // namespace fm::platform
