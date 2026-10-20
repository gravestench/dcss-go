-- Theory of operation: Honeycomb starts with a central cave, grows rough
-- floor outward, then divides it into adjacent pool territories whose
-- borders become rock walls. The source opens a bounded sample of those
-- shared walls as doors or plain passages and keeps the largest floor zone.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.room_geometry")
local spotty = require("policy.generation.layouts.spotty")
local cleanup = require("policy.generation.layouts.cave_cleanup")
local pools = require("policy.generation.layouts.pools")
local rooms = require("policy.generation.layouts.dis_rooms")
local regions = require("policy.generation.layouts.cell_graph")
local material = require("policy.generation.layouts.material")
local glyphs = require("constants.vault_glyphs")

local layout = {}

-- The source DIVISIONS gate counts ordinary floor and stairs, excluding
-- doors. The catalog retries the entire layout on a failed candidate.
function layout.validate(result)
    local count = 0
    local builder = result.builder

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "." or glyphs.up[glyph] or glyphs.down[glyph] then
                count = count + 1
            end
        end
    end

    return count > grid.width * grid.height * 0.15
end

-- Snake always opens plain gaps; Depths and Tartarus weight doors twice as
-- strongly as gaps. The choice is one draw for the entire floor.
local function connection_glyph(builder, branch)
    if branch == "Snake" or builder:roll(3) == 0 then
        return "."
    end

    return "+"
end

-- Run the source order on one shared builder: cave, room partitions,
-- adjacent-wall openings, zone fill, then branch material policy.
function layout.layout_honeycomb(api)
    local builder = grid.new(api.ctx)
    local center_x = grid.width / 2
    local center_y = grid.height / 2

    geometry.circle(builder, center_x, center_y, 10)
    builder:set(center_x, center_y, ".")
    spotty.carve(builder, true, 1500)
    cleanup.widen_paths(builder, "#", 50)
    cleanup.remove_isolated(builder, "#", 100, false)

    local connection = connection_glyph(builder, api.branch)
    local pool_size = 25 + builder:roll(25)
    local pool_count = pools.add(builder, pool_size, {
        { glyph = ".", weight = 1 },
    }, "#")

    rooms.connect(builder, 1000, 1500, "#", connection, 3)
    regions.keep_largest_region(builder)

    if connection == "." and api.branch == "Depths" then
        material.caves(builder, api)
    else
        material.level(builder, api)
    end

    if builder.bad_random then
        error("Honeycomb could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        pool_count = pool_count,
        connection = connection,
    }
end

return layout
