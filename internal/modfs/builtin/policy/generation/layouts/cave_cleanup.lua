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

-- The source's thirty-percent table accounts for each passable neighbor.
-- Collect replacements before painting so scan direction cannot bias them.
function cleanup.widen_paths(builder, target)
    local chance = { 0, 30, 52, 66, 76, 84, 89, 92, 95 }
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
