#include "app/Application.hpp"

#include "platform/GlfwWindow.hpp"
#include "presentation/theme/Theme.hpp"
#include "presentation/view/BrowserView.hpp"
#include "presentation/viewmodel/BrowserViewModel.hpp"

#include <imgui.h>

namespace fm::app {

Application::Application(Services services, std::filesystem::path assetDir)
    : services_(std::move(services)), assetDir_(std::move(assetDir)) {}

int Application::run() {
    const platform::GlfwWindow window{{.title = "Files (Dear ImGui)", .width = 1100, .height = 700}};

    presentation::applyTheme();
    ImGui::GetStyle().ScaleAllSizes(window.contentScale());
    ImGui::GetStyle().FontScaleDpi = window.contentScale();
    const auto fonts = presentation::loadFonts(assetDir_ / "fonts");

    presentation::BrowserViewModel viewModel{services_.browse, services_.places};
    presentation::BrowserView view{fonts};

    // A few frames after any input are rendered eagerly so hover/press
    // animations settle; otherwise we sleep until the next event.
    int eagerFrames = 2;
    while (!window.shouldClose()) {
        window.waitEvents(viewModel.isLoading() || eagerFrames > 0 ? 1.0 / 60.0 : 0.5);
        eagerFrames = ImGui::GetIO().InputQueueCharacters.empty() && !ImGui::IsAnyItemHovered() ? eagerFrames - 1 : 2;

        viewModel.tick();
        window.beginFrame();
        for (const auto& action : view.draw(viewModel)) {
            viewModel.dispatch(action);
        }
        window.endFrame();
    }
    return 0;
}

} // namespace fm::app
