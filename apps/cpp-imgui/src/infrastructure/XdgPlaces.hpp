#pragma once

#include "domain/Ports.hpp"

namespace fm::infrastructure {

/// Adapter: well-known places from the XDG user-dirs spec
/// (`$XDG_CONFIG_HOME/user-dirs.dirs`), with the usual `~/Name` fallbacks.
class XdgPlaces final : public domain::PlacesProvider {
public:
    [[nodiscard]] domain::DirectoryPath home() const override;
    [[nodiscard]] std::vector<domain::Place> places() const override;
};

} // namespace fm::infrastructure
