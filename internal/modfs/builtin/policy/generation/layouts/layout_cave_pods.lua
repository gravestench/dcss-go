-- Theory of operation: Cave Pods uses two cellular distance fields. The
-- first carves thin passages at feature-cell borders; the second opens broad
-- chambers near feature centers. A four-cell border suppresses edge caves,
-- then the shared region pass retains one traversable Dungeon component.
local grid = require("policy.generation.grid")
local cell_graph = require("policy.generation.layouts.cell_graph")
local noise = require("policy.generation.layouts.procedural_noise")

local layout = {}

-- Draw source-scale room and corridor fields once. Their large random
-- offsets are fixed before any map cells are sampled.
local function fields(builder, branch)
    local room_field = noise.worley(builder, 0.15)
    local corridor_field = noise.worley(builder, 0.1)
    local room_distortion
    local corridor_distortion

    if branch == "Snake" or branch == "Spider" then
        room_distortion = noise.damped_distortion(builder)
        corridor_distortion = noise.damped_distortion(builder)
    end

    return room_field, corridor_field, room_distortion, corridor_distortion
end

-- Thin low-difference bands form connecting corridors. The additive
-- border stops these bands from opening the immutable outer rim.
local function corridors(builder, field, distortion)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            local border = noise.border(x, y, 4, true)
            local value = noise.distorted_worley_at(field,
                distortion, x, y) + border * 0.3

            if value < 0.08 then
                builder:set(x, y, ".")
            end
        end
    end
end

-- High-difference plateaus are rounded pod interiors. This second pass
-- adds floor but never erases a previously carved corridor.
local function rooms(builder, field, distortion)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            local border = noise.border(x, y, 4, true)
            local value = noise.distorted_worley_at(field,
                distortion, x, y) - border

            if value > 0.4 then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Run the checked-in DES hook through the shared grid and connected-region
-- owner, including the source Snake and Spider distortion choice.
function layout.layout_cave_pods(api)
    local builder = grid.new(api.ctx)
    local room_field, corridor_field, room_distortion,
        corridor_distortion = fields(builder, api.branch)

    corridors(builder, corridor_field, corridor_distortion)
    rooms(builder, room_field, room_distortion)
    cell_graph.keep_largest_region(builder)

    if builder.bad_random then
        error("Cave Pods random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
    }
end

return layout
