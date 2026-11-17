#pragma once

#include "application/BrowseDirectory.hpp"
#include "application/ListPlaces.hpp"

#include <filesystem>

namespace fm::app {

/// Use cases handed over by the composition root.
struct Services {
    application::BrowseDirectory browse;
    application::ListPlaces places;
};

/// Owns the window and runs the frame loop: tick view model → draw view →
/// dispatch actions → render.
class Application {
  public:
    Application(Services services, std::filesystem::path assetDir);

    int run();

  private:
    Services services_;
    std::filesystem::path assetDir_;
};

} // namespace fm::app
