#include "platform/GlfwWindow.hpp"

#include "presentation/theme/Palette.hpp"

#include <GLFW/glfw3.h>
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

} // namespace fm::platform
