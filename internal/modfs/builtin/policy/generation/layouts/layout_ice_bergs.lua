-- Theory of operation: Cocytus begins as water. The first Worley field
-- draws connected shallow channels, the second adds rock, and the third
-- carves irregular berg floor without erasing earlier channels. The
-- source's disabled optional-isolation branch is intentionally absent.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local noise = require("policy.generation.layouts.procedural_noise")

local layout = {}

-- Render source's always-connected channels before placing bergs, so
-- later rock and floor tests can preserve cells whose field returns nil.
local function channels(builder, field)
    for x = 1, builder.width - 2 do
        for y = 1, builder.height - 2 do
            local glyph = noise.worley_at(field, x, y) < 0.1 and "W" or "w"

            builder:set(x, y, glyph)
        end
    end
end

-- High combined border and field values form permanent rock. Other
-- cells retain their previously chosen water or shallow channel glyph.
local function cave_rock(builder, field)
    for x = 1, builder.width - 2 do
        for y = 1, builder.height - 2 do
            local border = noise.border(x, y, 4, true, builder)
            local value = border + noise.worley_at(field, x, y)

            if value >= 0.8 then
                builder:set(x, y, "#")
            end
        end
    end
end

-- Cell centers become rock or floor while channel bands survive where
-- the third field has no replacement. This creates the source berg edges.
local function bergs(builder, field)
    for x = 1, builder.width - 2 do
        for y = 1, builder.height - 2 do
            local border = noise.border(x, y, 4, true, builder)
            local value = noise.worley_at(field, x, y) - border

            if value > 0.6 then
                builder:set(x, y, "#")
            elseif value > 0.2 then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Source zone cleanup keeps one floor/channel territory, but shallow
-- water outside it remains as scenery rather than new stair candidates.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local passages = noise.worley(builder, 0.15)
    local cave = noise.worley(builder, 0.2)
    local islands = noise.worley(builder, 0.2)

    channels(builder, passages)
    cave_rock(builder, cave)
    bergs(builder, islands)
    regions.keep_largest_region(builder, {
        ["."] = true,
        ["W"] = true,
    })

    return { builder = builder }
end

return layout
