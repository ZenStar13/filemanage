#include "app/Application.hpp"

#include "platform/GlfwWindow.hpp"
#include "presentation/theme/Theme.hpp"
#include "presentation/view/BrowserView.hpp"
#include "presentation/viewmodel/BrowserViewModel.hpp"

#include <imgui.h>

namespace fm::app {

Application::Application(Services services, std::filesystem::path assetDir)
    : services_(std::move(services)), assetDir_(std::move(assetDir)) {}

namespace {

/// Forwards a chrome request from the presentation layer to the platform.
void apply(platform::GlfwWindow& window, const presentation::WindowRequest& request) {
    using Kind = presentation::WindowRequest::Kind;
    switch (request.kind) {
    case Kind::Minimize:
        window.minimize();
        break;
    case Kind::ToggleMaximize:
        window.toggleMaximize();
        break;
    case Kind::Close:
        window.requestClose();
        break;
    case Kind::BeginMove:
        window.beginMove();
        break;
    case Kind::BeginResize:
        window.beginResize(request.edges); // same bit layout as GlfwWindow::Edge
        break;
    }
}

} // namespace

int Application::run() {
    platform::GlfwWindow window{{.title = "Files (Dear ImGui)", .width = 1100, .height = 700}};

    presentation::applyTheme();
    ImGui::GetStyle().ScaleAllSizes(window.contentScale());
    ImGui::GetStyle().FontScaleDpi = window.contentScale();
    const auto fonts = presentation::loadFonts(assetDir_ / "fonts");

    presentation::BrowserViewModel viewModel{services_.browse, services_.places};
    presentation::BrowserView view{fonts};

    // Dear ImGui spreads queued input events over several frames ("input
    // trickling"), so after any OS event we render a short burst at 60 FPS;
    // otherwise we sleep until the next event (or poll while loading).
    constexpr int kBurstFrames = 20;
    int burst = kBurstFrames;
    while (!window.shouldClose()) {
        const bool busy = burst > 0 || viewModel.isLoading() || window.isInteracting();
        burst = window.waitEvents(busy ? 1.0 / 60.0 : 0.5) ? kBurstFrames : burst - 1;

        viewModel.tick();
        window.beginFrame();
        auto frame = view.draw(viewModel, window.isMaximized());
        for (const auto& action : frame.actions) {
            viewModel.dispatch(action);
        }
        for (const auto& request : frame.window) {
            apply(window, request);
        }
        window.updateInteraction();
        window.endFrame();
    }
    return 0;
}

} // namespace fm::app
