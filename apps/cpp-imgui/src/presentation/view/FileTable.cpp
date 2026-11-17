#include "presentation/Format.hpp"
#include "presentation/theme/Glyphs.hpp"
#include "presentation/theme/Palette.hpp"
#include "presentation/view/Views.hpp"

#include <imgui.h>

namespace fm::presentation::view {

namespace {

constexpr float kSizeWidth = 110;
constexpr float kModifiedWidth = 160;
constexpr float kKindWidth = 150;
constexpr float kHeaderHeight = dimens::kRowHeight + 4;

/// Centered hint drawn inside the (scrolling) table window.
void emptyState(const char* message) {
    const ImVec2 pos = ImGui::GetWindowPos();
    const ImVec2 size = ImGui::GetWindowSize();
    const ImVec2 text = ImGui::CalcTextSize(message);
    ImGui::GetWindowDrawList()->AddText(
        {pos.x + (size.x - text.x) / 2, pos.y + (size.y - text.y) / 2},
        ImGui::GetColorU32(palette::kTextSecondary), message);
}

void mutedCell(const std::string& text, bool alignRight = false) {
    ImGui::PushFont(nullptr, dimens::kFontSmall);
    ImGui::SetCursorPosY(ImGui::GetCursorPosY() + (dimens::kRowHeight - ImGui::GetFontSize()) / 2);
    if (alignRight) {
        ImGui::SetCursorPosX(ImGui::GetCursorPosX() + ImGui::GetContentRegionAvail().x -
                             ImGui::CalcTextSize(text.c_str()).x);
    }
    ImGui::TextColored(palette::kTextSecondary, "%s", text.c_str());
    ImGui::PopFont();
}

} // namespace

void FileTable::draw(const BrowserViewModel& vm, ActionQueue& actions, const Fonts& fonts) {
    const auto& entries = vm.entries();
    constexpr ImGuiTableFlags kFlags = ImGuiTableFlags_ScrollY | ImGuiTableFlags_RowBg |
                                       ImGuiTableFlags_Resizable | ImGuiTableFlags_BordersInnerV |
                                       ImGuiTableFlags_PadOuterX | ImGuiTableFlags_NoSavedSettings;

    if (!ImGui::BeginTable("##entries", 4, kFlags, ImGui::GetContentRegionAvail())) {
        return;
    }
    ImGui::TableSetupScrollFreeze(0, 1);
    ImGui::TableSetupColumn("Name", ImGuiTableColumnFlags_WidthStretch);
    ImGui::TableSetupColumn("Size", ImGuiTableColumnFlags_WidthFixed, kSizeWidth);
    ImGui::TableSetupColumn("Modified", ImGuiTableColumnFlags_WidthFixed, kModifiedWidth);
    ImGui::TableSetupColumn("Kind", ImGuiTableColumnFlags_WidthFixed, kKindWidth);

    // Gold, bold, small header row.
    ImGui::PushFont(fonts.bold, dimens::kFontSmall);
    ImGui::PushStyleColor(ImGuiCol_Text, palette::kGold);
    ImGui::TableNextRow(ImGuiTableRowFlags_Headers, kHeaderHeight);
    for (int column = 0; column < 4; ++column) {
        ImGui::TableSetColumnIndex(column);
        ImGui::Dummy({0, 4}); // vertical centering without moving the cursor manually
        ImGui::TableHeader(ImGui::TableGetColumnName(column));
    }
    ImGui::PopStyleColor();
    ImGui::PopFont();

    // Reveal the selection when it was moved with the keyboard.
    if (vm.revealRevision() != revealedRevision_) {
        revealedRevision_ = vm.revealRevision();
        if (const auto index = vm.selectedIndex()) {
            const float rowTop = static_cast<float>(*index) * dimens::kRowHeight;
            const float viewHeight = ImGui::GetWindowHeight() - kHeaderHeight;
            if (rowTop < ImGui::GetScrollY()) {
                ImGui::SetScrollY(rowTop);
            } else if (rowTop + dimens::kRowHeight > ImGui::GetScrollY() + viewHeight) {
                ImGui::SetScrollY(rowTop + dimens::kRowHeight - viewHeight);
            }
        }
    }

    // Only visible rows are submitted: cheap even for /usr/lib.
    ImGuiListClipper clipper;
    clipper.Begin(static_cast<int>(entries.size()), dimens::kRowHeight);
    while (clipper.Step()) {
        for (int row = clipper.DisplayStart; row < clipper.DisplayEnd; ++row) {
            const auto& entry = *entries[static_cast<std::size_t>(row)];
            const bool selected = vm.selected() == entry.path;
            const auto icon = glyphs::forEntry(entry);

            ImGui::TableNextRow(ImGuiTableRowFlags_None, dimens::kRowHeight);
            ImGui::TableSetColumnIndex(0);
            ImGui::PushID(row);

            const ImVec2 rowStart = ImGui::GetCursorScreenPos();
            if (ImGui::Selectable("##row", selected,
                                  ImGuiSelectableFlags_SpanAllColumns |
                                      ImGuiSelectableFlags_AllowDoubleClick |
                                      ImGuiSelectableFlags_AllowOverlap,
                                  {0, dimens::kRowHeight})) {
                if (ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
                    actions.emplace_back(action::Activate{entry.path});
                } else {
                    actions.emplace_back(action::Select{entry.path});
                }
            }
            if (entry.isNavigable() && ImGui::IsItemHovered()) {
                ImGui::SetMouseCursor(ImGuiMouseCursor_Hand);
            }
            if (selected) {
                // Aqua outline around the whole row. Cells clip to their column,
                // so widen the clip rect to the table body (below the header).
                const ImVec2 winPos = ImGui::GetWindowPos();
                const ImVec2 winSize = ImGui::GetWindowSize();
                const float left = winPos.x + 1;
                const float scrollbar =
                    ImGui::GetScrollMaxY() > 0 ? ImGui::GetStyle().ScrollbarSize : 0;
                const ImVec2 rowEnd{winPos.x + winSize.x - scrollbar - 1,
                                    rowStart.y + dimens::kRowHeight};
                ImDrawList* outline = ImGui::GetWindowDrawList();
                outline->PushClipRect({winPos.x, winPos.y + kHeaderHeight},
                                      {winPos.x + winSize.x, winPos.y + winSize.y});
                outline->AddRect({left, rowStart.y}, rowEnd, ImGui::GetColorU32(palette::kAqua),
                                 dimens::kRadiusSm);
                outline->PopClipRect();
            }

            ImGui::SameLine(0, 0);
            const float textY = rowStart.y + (dimens::kRowHeight - ImGui::GetFontSize()) / 2;
            ImDrawList* draw = ImGui::GetWindowDrawList();
            draw->AddText({rowStart.x + dimens::kXs, textY}, ImGui::GetColorU32(icon.color),
                          icon.glyph);
            draw->PushClipRect(
                rowStart, {rowStart.x + ImGui::GetColumnWidth(), rowStart.y + dimens::kRowHeight},
                true);
            draw->AddText({rowStart.x + dimens::kXs + 26, textY},
                          ImGui::GetColorU32(palette::kTextPrimary), entry.name.c_str());
            draw->PopClipRect();

            ImGui::TableSetColumnIndex(1);
            mutedCell(format::entrySize(entry), true);
            ImGui::TableSetColumnIndex(2);
            mutedCell(format::modified(entry));
            ImGui::TableSetColumnIndex(3);
            mutedCell(format::kind(entry));
            ImGui::PopID();
        }
    }
    if (entries.empty()) {
        emptyState(vm.isLoading() ? "Loading\u2026" : "This folder is empty");
    }
    ImGui::EndTable();
}

} // namespace fm::presentation::view
