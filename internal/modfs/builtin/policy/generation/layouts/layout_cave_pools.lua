-- Theory of operation: Cave Pools grows a rough cave from a center floor
-- seed, removes isolated rock, and partitions its open floor into pools.
-- Dungeon pool materials are floor and rock; Depths may also choose water
-- or lava. Two cleanup passes keep corridors traversable between pools.
local grid = require("policy.generation.grid")
local spotty = require("policy.generation.layouts.spotty")
local cleanup = require("policy.generation.layouts.cave_cleanup")
local pools = require("policy.generation.layouts.pools")
local material = require("policy.generation.layouts.material")

local layout = {}

-- Source pool weights vary by absolute depth. Clamp the rock weight at zero
-- because negative values cannot represent a material in the pool draw.
local function pool_contents(builder, api)
    local absolute_depth = api.absolute_depth or api.depth
    local rock_weight

    if api.branch == "D" then
        rock_weight = 120 - absolute_depth * 6
    else
        rock_weight = 40 - absolute_depth
    end

    local contents = {
        { glyph = ".", weight = 40 },
        { glyph = "#", weight = math.max(0, rock_weight) },
    }

    if api.branch == "Depths" then
        local glyph = api.depth >= builder:roll(8) and "l" or "w"
        local weight = absolute_depth * builder:roll(100) / 100

        contents[#contents + 1] = {
            glyph = glyph,
            weight = weight,
        }
    end

    return contents
end

-- Run the named DES hook in the source order. A central floor patch is
-- required before spotty growth can find any existing open edge.
function layout.layout_cave_pools(api)
    local builder = grid.new(api.ctx)
    local center_x = math.floor(grid.width / 2)
    local center_y = math.floor(grid.height / 2)

    builder:set(center_x, center_y, ".")
    spotty.carve(builder, false, 1000)
    cleanup.remove_isolated(builder, "#", 100, false)

    local contents = pool_contents(builder, api)
    local pool_size = 10 + builder:roll(15)
    local pool_count = pools.add(builder, pool_size, contents)

    cleanup.widen_paths(builder, "#")
    cleanup.remove_isolated(builder, "#", 80, false)
    cleanup.widen_paths(builder, "l")
    cleanup.remove_isolated(builder, "l", 75, true)
    material.caves(builder, api)

    if builder.bad_random then
        error("cave pools random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        pool_count = pool_count,
        pool_contents = contents,
    }
end

return layout
