#include "platform/GlfwWindow.hpp"

#include "presentation/theme/Palette.hpp"

#include <GLFW/glfw3.h>
#include <algorithm>
#include <cstdio>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <stdexcept>

namespace fm::platform {

namespace {

void onGlfwError(int code, const char* description) {
    std::fprintf(stderr, "GLFW error %d: %s\n", code,
                 description); // NOLINT(cppcoreguidelines-pro-type-vararg)
}

} // namespace

GlfwWindow::GlfwWindow(const Options& options) {
    glfwSetErrorCallback(onGlfwError);
    if (glfwInit() == GLFW_FALSE) {
        throw std::runtime_error("Failed to initialise GLFW");
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    // Client-side decorations: the UI draws its own title bar and controls.
    glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);

    scale_ = ImGui_ImplGlfw_GetContentScaleForMonitor(glfwGetPrimaryMonitor());
    window_ = glfwCreateWindow(static_cast<int>(static_cast<float>(options.width) * scale_),
                               static_cast<int>(static_cast<float>(options.height) * scale_),
                               options.title.c_str(), nullptr, nullptr);
    if (window_ == nullptr) {
        glfwTerminate();
        throw std::runtime_error("Failed to create window");
    }
    glfwMakeContextCurrent(window_);
    glfwSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr; // Layout is code-defined; nothing to persist.
    // Keyboard navigation is handled by our own shortcuts / selection model.
    io.ConfigFlags &= ~ImGuiConfigFlags_NavEnableKeyboard;

    ImGui_ImplGlfw_InitForOpenGL(window_, true);
    ImGui_ImplOpenGL3_Init("#version 130");
}

GlfwWindow::~GlfwWindow() {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window_);
    glfwTerminate();
}

bool GlfwWindow::shouldClose() const {
    return glfwWindowShouldClose(window_) != 0;
}

bool GlfwWindow::waitEvents(double timeoutSeconds) const {
    const double start = glfwGetTime();
    glfwWaitEventsTimeout(timeoutSeconds);
    return glfwGetTime() - start < timeoutSeconds * 0.9;
}

void GlfwWindow::beginFrame() const {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
}

void GlfwWindow::endFrame() const {
    ImGui::Render();
    int width = 0;
    int height = 0;
    glfwGetFramebufferSize(window_, &width, &height);
    glViewport(0, 0, width, height);
    const auto& bg = presentation::palette::kBackground;
    glClearColor(bg.x, bg.y, bg.z, bg.w);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glfwSwapBuffers(window_);
}

void GlfwWindow::minimize() const {
    glfwIconifyWindow(window_);
}

void GlfwWindow::toggleMaximize() const {
    if (isMaximized()) {
        glfwRestoreWindow(window_);
    } else {
        glfwMaximizeWindow(window_);
    }
}

bool GlfwWindow::isMaximized() const {
    return glfwGetWindowAttrib(window_, GLFW_MAXIMIZED) == GLFW_TRUE;
}

void GlfwWindow::requestClose() const {
    glfwSetWindowShouldClose(window_, GLFW_TRUE);
}

void GlfwWindow::screenCursor(double& x, double& y) const {
    int windowX = 0;
    int windowY = 0;
    glfwGetWindowPos(window_, &windowX, &windowY);
    glfwGetCursorPos(window_, &x, &y);
    x += windowX;
    y += windowY;
}

void GlfwWindow::beginMove() {
    if (isMaximized()) {
        return; // Like most WMs: a maximised window does not move.
    }
    interaction_ = Interaction::Move;
    screenCursor(anchorX_, anchorY_);
    glfwGetWindowPos(window_, &startX_, &startY_);
}

void GlfwWindow::beginResize(unsigned edges) {
    if (isMaximized() || edges == 0) {
        return;
    }
    interaction_ = Interaction::Resize;
    edges_ = edges;
    screenCursor(anchorX_, anchorY_);
    glfwGetWindowPos(window_, &startX_, &startY_);
    glfwGetWindowSize(window_, &startWidth_, &startHeight_);
}

void GlfwWindow::updateInteraction() {
    if (interaction_ == Interaction::None) {
        return;
    }
    if (glfwGetMouseButton(window_, GLFW_MOUSE_BUTTON_LEFT) != GLFW_PRESS) {
        interaction_ = Interaction::None;
        return;
    }
    double x = 0;
    double y = 0;
    screenCursor(x, y);
    const int dx = static_cast<int>(x - anchorX_);
    const int dy = static_cast<int>(y - anchorY_);
    if (interaction_ == Interaction::Move) {
        glfwSetWindowPos(window_, startX_ + dx, startY_ + dy);
        return;
    }
    constexpr int kMinWidth = 640;
    constexpr int kMinHeight = 400;
    int left = startX_;
    int top = startY_;
    int width = startWidth_;
    int height = startHeight_;
    if ((edges_ & Right) != 0U) {
        width = std::max(kMinWidth, startWidth_ + dx);
    }
    if ((edges_ & Bottom) != 0U) {
        height = std::max(kMinHeight, startHeight_ + dy);
    }
    if ((edges_ & Left) != 0U) {
        width = std::max(kMinWidth, startWidth_ - dx);
        left = startX_ + startWidth_ - width;
    }
    if ((edges_ & Top) != 0U) {
        height = std::max(kMinHeight, startHeight_ - dy);
        top = startY_ + startHeight_ - height;
    }
    glfwSetWindowPos(window_, left, top);
    glfwSetWindowSize(window_, width, height);
}

} // namespace fm::platform
