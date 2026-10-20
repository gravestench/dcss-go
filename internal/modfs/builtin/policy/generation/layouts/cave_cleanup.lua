-- Source cave cleanup removes single isolated cells and widens narrow paths.
-- It reads the shared grid directly and leaves the immutable outer rim alone.
local grid = require("policy.generation.grid")

local cleanup = {}

local cardinal = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

local diagonal = {
    { x = 1, y = 1 },
    { x = -1, y = 1 },
    { x = 1, y = -1 },
    { x = -1, y = -1 },
}

-- Match the source's pointy or rounded radius-one neighborhood without
-- copying a layout-specific list of cells into every cave algorithm.
local function neighbors(boxy)
    if not boxy then
        return cardinal
    end

    local all = {}

    for _, offset in ipairs(cardinal) do
        all[#all + 1] = offset
    end

    for _, offset in ipairs(diagonal) do
        all[#all + 1] = offset
    end

    return all
end

-- An isolated glyph has no same-glyph neighbor in the chosen shape. This
-- pass updates as it scans, like source remove_isolated_glyphs.
function cleanup.remove_isolated(builder, target, percent, boxy)
    local offsets = neighbors(boxy)

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == target and builder:chance_in(percent, 100) then
                local isolated = true

                for _, offset in ipairs(offsets) do
                    if builder:cell(x + offset.x, y + offset.y) == target then
                        isolated = false
                        break
                    end
                end

                if isolated then
                    builder:set(x, y, ".")
                end
            end
        end
    end
end

-- The source has two exact tables to preserve old seed quirks. Other
-- percentages use an integer recurrence, not a floating-point power.
local function widening_chances(percent)
    if percent == 30 then
        return { 0, 30, 52, 66, 76, 84, 89, 92, 95 }
    elseif percent == 50 then
        return { 0, 50, 75, 88, 94, 97, 99, 100, 100 }
    end

    local anti = 10 - math.floor(percent / 10)
    local numerator = 10 * anti
    local divisor = 1
    local chances = { 0 }

    for index = 2, 9 do
        chances[index] = 100 - math.floor(numerator / divisor)
        numerator = numerator * anti
        divisor = divisor * 10
    end

    return chances
end

-- Collect replacements before painting so scan direction cannot bias
-- them. The percent parameter lets Gehenna use its four source passes.
function cleanup.widen_paths(builder, target, percent)
    local chance = widening_chances(percent or 30)
    local offsets = neighbors(true)
    local replacements = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == target then
                local adjacent = 0

                for _, offset in ipairs(offsets) do
                    if builder:cell(x + offset.x, y + offset.y) == "." then
                        adjacent = adjacent + 1
                    end
                end

                if builder:chance_in(chance[adjacent + 1], 100) then
                    replacements[#replacements + 1] = { x = x, y = y }
                end
            end
        end
    end

    for _, point in ipairs(replacements) do
        builder:set(point.x, point.y, ".")
    end
end

return cleanup
