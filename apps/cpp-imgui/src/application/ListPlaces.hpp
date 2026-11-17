#pragma once

#include "domain/Ports.hpp"

#include <memory>
#include <vector>

namespace fm::application {

/// Use case: sidebar shortcuts and the starting location.
class ListPlaces {
public:
    explicit ListPlaces(std::shared_ptr<const domain::PlacesProvider> provider);

    [[nodiscard]] std::vector<domain::Place> operator()() const;
    [[nodiscard]] domain::DirectoryPath startLocation() const;

private:
    std::shared_ptr<const domain::PlacesProvider> provider_;
};

} // namespace fm::application
