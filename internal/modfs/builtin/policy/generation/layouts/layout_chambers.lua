-- Theory of operation: two fixed Worley fields partition Snake, Spider,
-- and Pan into passages and chambers. Low difference values mark narrow
-- paths between feature cells; high values open their centers. A four-cell
-- border discourages caves at the map edge. The source computes a third
-- hall expression but never paints it, so there is no hall pass here.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local noise = require("policy.generation.layouts.procedural_noise")

local layout = {}

-- Source corridor scale and threshold differ from Cave Pods, giving
-- Chambers a broader mesh before the room pass expands its openings.
local function paint_corridors(builder, field)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            local border = noise.border(x, y, 4, true)
            local value = noise.worley_at(field, x, y) + border * 0.3

            if value < 0.15 then
                builder:set(x, y, ".")
            end
        end
    end
end

-- The room pass only adds floor. It cannot erase a connecting passage
-- from the first pass, which is why the source draws these fields in order.
local function paint_rooms(builder, field)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            local border = noise.border(x, y, 4, true)
            local value = noise.worley_at(field, x, y) - border

            if value > 0.3 then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Save the two random field offsets before reading any cells; map scan
-- order therefore does not change the chosen source noise realization.
function layout.generate(api)
    local builder = grid.new(api.ctx)
    local rooms = noise.worley(builder, 0.2)
    local corridors = noise.worley(builder, 0.3)

    paint_corridors(builder, corridors)
    paint_rooms(builder, rooms)
    regions.keep_largest_region(builder)

    return { builder = builder }
end

return layout
