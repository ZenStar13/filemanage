#include "presentation/Format.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <ctime>
#include <format>

namespace fm::presentation::format {

std::string size(std::uintmax_t bytes) {
    static constexpr std::array kUnits{"B", "KiB", "MiB", "GiB", "TiB", "PiB"};
    auto value = static_cast<double>(bytes);
    std::size_t unit = 0;
    while (value >= 1024.0 && unit + 1 < kUnits.size()) {
        value /= 1024.0;
        ++unit;
    }
    return unit == 0 ? std::format("{} B", bytes) : std::format("{:.1f} {}", value, kUnits.at(unit));
}

std::string entrySize(const domain::FileEntry& entry) {
    return entry.size ? size(*entry.size) : "—";
}

std::string modified(const domain::FileEntry& entry) {
    if (!entry.modified) {
        return "—";
    }
    const std::time_t t = std::chrono::system_clock::to_time_t(*entry.modified);
    std::tm local{};
    localtime_r(&t, &local);
    std::array<char, 32> buffer{};
    const auto n = std::strftime(buffer.data(), buffer.size(), "%Y-%m-%d %H:%M", &local);
    return {buffer.data(), n};
}

std::string kind(const domain::FileEntry& entry) {
    using domain::EntryKind;
    switch (entry.kind) {
    case EntryKind::Directory: return "Folder";
    case EntryKind::SymlinkToDirectory: return "Link to folder";
    case EntryKind::SymlinkToFile: return "Link";
    case EntryKind::Other: return "Special";
    case EntryKind::File: break;
    }
    auto ext = entry.extension();
    if (ext.empty()) {
        return "File";
    }
    std::ranges::transform(ext, ext.begin(),
                           [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
    return ext + " file";
}

std::string summary(const domain::ListingSummary& s, bool showingHidden) {
    const auto plural = [](std::size_t n, std::string_view word) {
        return std::format("{} {}{}", n, word, n == 1 ? "" : "s");
    };
    auto text = std::format("{} · {} ({})", plural(s.folders, "folder"), plural(s.files, "file"),
                            size(s.totalBytes));
    if (!showingHidden && s.hidden > 0) {
        text += std::format(" · {} hidden", s.hidden);
    }
    return text;
}

} // namespace fm::presentation::format
