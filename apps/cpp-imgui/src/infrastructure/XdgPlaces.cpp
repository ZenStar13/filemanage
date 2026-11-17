#include "infrastructure/XdgPlaces.hpp"

#include <array>
#include <cstdlib>
#include <fstream>
#include <map>
#include <string_view>

namespace fm::infrastructure {

namespace fs = std::filesystem;
using domain::DirectoryPath;
using domain::Place;
using domain::PlaceKind;

namespace {

std::string env(const char* name) {
    const char* value = std::getenv(name); // NOLINT(concurrency-mt-unsafe): read at startup only
    return value != nullptr ? value : "";
}

/// Parses lines like `XDG_DOCUMENTS_DIR="$HOME/Documents"`.
std::map<std::string, std::string> readUserDirs(const fs::path& home) {
    const auto configHome = env("XDG_CONFIG_HOME");
    const fs::path file = (configHome.empty() ? home / ".config" : fs::path{configHome}) / "user-dirs.dirs";
    std::map<std::string, std::string> dirs;
    std::ifstream in{file};
    for (std::string line; std::getline(in, line);) {
        const auto eq = line.find('=');
        if (line.starts_with('#') || eq == std::string::npos) {
            continue;
        }
        auto value = line.substr(eq + 1);
        if (value.size() >= 2 && value.front() == '"' && value.back() == '"') {
            value = value.substr(1, value.size() - 2);
        }
        if (constexpr std::string_view kHome = "$HOME"; value.starts_with(kHome)) {
            value = home.string() + value.substr(kHome.size());
        }
        dirs.emplace(line.substr(0, eq), std::move(value));
    }
    return dirs;
}

} // namespace

DirectoryPath XdgPlaces::home() const {
    return DirectoryPath::from(env("HOME")).value_or(DirectoryPath::root());
}

std::vector<Place> XdgPlaces::places() const {
    struct Candidate {
        PlaceKind kind;
        std::string_view label;
        std::string_view xdgKey;
    };
    static constexpr std::array kCandidates{
        Candidate{PlaceKind::Desktop, "Desktop", "XDG_DESKTOP_DIR"},
        Candidate{PlaceKind::Documents, "Documents", "XDG_DOCUMENTS_DIR"},
        Candidate{PlaceKind::Downloads, "Downloads", "XDG_DOWNLOAD_DIR"},
        Candidate{PlaceKind::Pictures, "Pictures", "XDG_PICTURES_DIR"},
        Candidate{PlaceKind::Music, "Music", "XDG_MUSIC_DIR"},
        Candidate{PlaceKind::Videos, "Videos", "XDG_VIDEOS_DIR"},
    };

    const auto homeDir = home();
    const auto userDirs = readUserDirs(homeDir.value());

    std::vector<Place> result{Place{.kind = PlaceKind::Home, .label = "Home", .path = homeDir}};
    for (const auto& [kind, label, key] : kCandidates) {
        const auto it = userDirs.find(std::string{key});
        const fs::path raw = it != userDirs.end() ? fs::path{it->second} : homeDir.value() / label;
        std::error_code ec;
        auto path = DirectoryPath::from(raw);
        // XDG: a user dir equal to $HOME means "disabled".
        if (path && *path != homeDir && fs::is_directory(raw, ec)) {
            result.push_back(Place{.kind = kind, .label = std::string{label}, .path = std::move(*path)});
        }
    }
    result.push_back(Place{.kind = PlaceKind::Root, .label = "File System", .path = DirectoryPath::root()});
    return result;
}

} // namespace fm::infrastructure
