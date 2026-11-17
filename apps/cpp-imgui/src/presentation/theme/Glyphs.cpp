#include "presentation/theme/Glyphs.hpp"

#include "presentation/theme/Palette.hpp"

#include <array>
#include <string_view>

namespace fm::presentation::glyphs {

namespace {

struct ExtensionIcon {
    std::string_view extension;
    const char* glyph;
    bool media;
};

constexpr auto kExtensionIcons = std::to_array<ExtensionIcon>({
    {"png", "", true},   {"jpg", "", true},   {"jpeg", "", true},  {"gif", "", true},
    {"svg", "", true},   {"webp", "", true},  {"mp3", "", true},   {"flac", "", true},
    {"ogg", "", true},   {"wav", "", true},   {"mp4", "", true},   {"mkv", "", true},
    {"webm", "", true},  {"mov", "", true},   {"zip", "", false},  {"tar", "", false},
    {"gz", "", false},   {"xz", "", false},   {"zst", "", false},  {"7z", "", false},
    {"deb", "", false},  {"pdf", "", false},  {"txt", "", false},  {"md", "", false},
    {"log", "", false},  {"conf", "", false}, {"ini", "", false},  {"cpp", "", false},
    {"hpp", "", false},  {"c", "", false},    {"h", "", false},    {"rs", "", false},
    {"zig", "", false},  {"dart", "", false}, {"py", "", false},   {"js", "", false},
    {"ts", "", false},   {"sh", "", false},   {"json", "", false}, {"toml", "", false},
    {"yaml", "", false}, {"yml", "", false},  {"html", "", false}, {"css", "", false},
});

} // namespace

Icon forEntry(const domain::FileEntry& entry) {
    using domain::EntryKind;
    switch (entry.kind) {
    case EntryKind::Directory:
        return {kFolder, palette::kAqua};
    case EntryKind::SymlinkToDirectory:
    case EntryKind::SymlinkToFile:
        return {kSymlink, palette::kPurple};
    case EntryKind::Other:
        return {"", palette::kTextSecondary};
    case EntryKind::File:
        break;
    }
    const auto ext = entry.extension();
    for (const auto& icon : kExtensionIcons) {
        if (icon.extension == ext) {
            return {icon.glyph, icon.media ? palette::kGold : palette::kTextSecondary};
        }
    }
    return {kFile, palette::kTextSecondary};
}

const char* forPlace(domain::PlaceKind kind) {
    using domain::PlaceKind;
    switch (kind) {
    case PlaceKind::Home:
        return "";
    case PlaceKind::Desktop:
        return "";
    case PlaceKind::Documents:
        return "";
    case PlaceKind::Downloads:
        return "";
    case PlaceKind::Pictures:
        return "";
    case PlaceKind::Music:
        return "";
    case PlaceKind::Videos:
        return "";
    case PlaceKind::Root:
        return "";
    }
    return kFolder;
}

} // namespace fm::presentation::glyphs
