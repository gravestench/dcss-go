-- Theory of operation: source Long Grid keeps cutting one axis down to its
-- minimum before it cuts the other. The resulting long cells create lengthy
-- passages. Dungeon makes some corridors narrow for tactical fairness;
-- Lair keeps the wider organic variant unless its source rarity draw fires.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- Keep the axis choice and Dungeon corridor exception beside this layout's
-- source hook, while the shared painter owns only generic geometry.
function layout.layout_long_grid(api)
    local builder = grid.new(api.ctx)
    local lair = api.branch == "Lair"
    local dungeon = api.branch == "D"
    local size = subdivision.range(builder, lair and 1 or 2, lair and 4 or 3)
    local options = {
        guaranteed_divides = 0,
        initial_chance = 100,
        multiplier = 1,
        minimum_size_x = size * 2,
        minimum_size_y = size * subdivision.range(builder, 4, 6),
    }
    local paint = {
        fill_chance = subdivision.range(builder, 40 + size * 10, 80 + size * 5),
        corridor_width = size,
        outer_corridor = lair,
        jitter = false,
    }

    if dungeon or (lair and size > 1 and builder:one_in(3)) then
        paint.corridor_width = 1
        paint.jitter = true
        paint.jitter_min = -1
        paint.jitter_max = 0

        if dungeon then
            paint.outer_corridor = builder:roll(2) == 0
        end
    end

    options.axis = builder:roll(2) == 0 and "x" or "y"

    if options.axis == "y" then
        options.minimum_size_x, options.minimum_size_y =
            options.minimum_size_y, options.minimum_size_x
    end

    local cells = subdivision.render(builder, options, paint)

    if builder.bad_random then
        error("long grid random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
    }
end

return layout
