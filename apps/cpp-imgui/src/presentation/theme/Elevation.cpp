#include "presentation/theme/Elevation.hpp"

#include "presentation/theme/Glyphs.hpp"

#include <algorithm>
#include <cmath>

namespace fm::presentation::elevation {

namespace {

ImU32 black(float alpha) {
    return ImGui::GetColorU32(ImVec4{0, 0, 0, alpha});
}

} // namespace

void castRight(ImDrawList* draw, const ImVec2& casterMin, const ImVec2& casterMax,
               const Shadow& shadow) {
    // The offset pushes the darkest part away from the edge; blur sets the falloff.
    const float x = casterMax.x;
    const float width = shadow.x + shadow.blur;
    draw->AddRectFilledMultiColor({x, casterMin.y}, {x + width, casterMax.y}, black(shadow.alpha),
                                  black(0), black(0), black(shadow.alpha));
}

void castDown(ImDrawList* draw, const ImVec2& casterMin, const ImVec2& casterMax,
              const Shadow& shadow) {
    const float y = casterMax.y;
    const float height = shadow.y + shadow.blur;
    draw->AddRectFilledMultiColor({casterMin.x, y}, {casterMax.x, y + height}, black(shadow.alpha),
                                  black(shadow.alpha), black(0), black(0));
}

void softShadow(ImDrawList* draw, const ImVec2& min, const ImVec2& max, const Shadow& shadow,
                float rounding) {
    // Approximate a Gaussian blur with concentric, increasingly larger rects:
    // their alphas accumulate towards the centre and fade out at the rim.
    const int steps = std::max(1, static_cast<int>(std::ceil(shadow.blur)));
    const float layerAlpha = shadow.alpha / static_cast<float>(steps);
    for (int i = steps; i >= 1; --i) {
        const float grow = static_cast<float>(i) - 1.0F;
        draw->AddRectFilled({min.x + shadow.x - grow, min.y + shadow.y - grow + 1.0F},
                            {max.x + shadow.x + grow, max.y + shadow.y + grow}, black(layerAlpha),
                            rounding + grow);
    }
}

float opticalOffset(std::string_view glyph) {
    if (glyph == glyphs::kBack || glyph == glyphs::kForward) {
        return 0.094F;
    }
    if (glyph == glyphs::kUp) {
        return 0.036F;
    }
    if (glyph == glyphs::kRefresh) {
        return 0.122F;
    }
    if (glyph == glyphs::kEye) {
        return 0.209F;
    }
    if (glyph == glyphs::kEyeSlash) {
        return 0.268F;
    }
    return 0.0F;
}

} // namespace fm::presentation::elevation
