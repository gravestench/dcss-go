-- Theory of operation: Vaults crosses are two intersecting floor strips.
-- The variable form can make corners and T junctions; the centered form is
-- a narrow, unmistakable cross. Intersections stay open before rooms attach.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.vaults.geometry")

local crosses = {}

-- Choose strip positions and lengths from the source ranges, then bound
-- their starts so each strip intersects the other despite random offsets.
function crosses.omnicross(builder)
    local horizontal_width = geometry.range(builder, 4, 20)
    local vertical_width = geometry.range(builder, 4, 20)
    local horizontal_y = geometry.range(builder, 1,
        grid.height - horizontal_width - 1)
    local vertical_x = geometry.range(builder, 1,
        grid.width - vertical_width - 1)
    local horizontal_length = geometry.range(builder,
        math.ceil((grid.width + 1) / 2), grid.width - 2)
    local vertical_length = geometry.range(builder,
        math.ceil((grid.height + 1) / 2), grid.height - 2)
    local horizontal_x = geometry.range(builder,
        math.max(1, vertical_x + vertical_width - horizontal_length),
        math.min(vertical_x, grid.width - horizontal_length - 1))
    local vertical_y = geometry.range(builder,
        math.max(1, horizontal_y + horizontal_width - vertical_length),
        math.min(horizontal_y, grid.height - vertical_length - 1))

    geometry.rectangle(builder, horizontal_x, horizontal_y,
        horizontal_x + horizontal_length - 1,
        horizontal_y + horizontal_width - 1, ".")
    geometry.rectangle(builder, vertical_x, vertical_y,
        vertical_x + vertical_width - 1,
        vertical_y + vertical_length - 1, ".")
end

-- The source uses the average of two three-sided rolls for a three to five
-- cell center width. Full-length arms leave room for side chambers.
function crosses.big_cross(builder)
    local width = 3 + math.floor((builder:roll(3) + builder:roll(3)) / 2)
    local center_x = math.floor((grid.width - width) / 2)
    local center_y = math.floor((grid.height - width) / 2)

    geometry.rectangle(builder, center_x, 1,
        center_x + width - 1, grid.height - 2, ".")
    geometry.rectangle(builder, 1, center_y,
        grid.width - 2, center_y + width - 1, ".")
end

return crosses
