#include "application/ListPlaces.hpp"

namespace fm::application {

ListPlaces::ListPlaces(std::shared_ptr<const domain::PlacesProvider> provider)
    : provider_(std::move(provider)) {}

std::vector<domain::Place> ListPlaces::operator()() const {
    return provider_->places();
}

domain::DirectoryPath ListPlaces::startLocation() const {
    return provider_->home();
}

} // namespace fm::application
