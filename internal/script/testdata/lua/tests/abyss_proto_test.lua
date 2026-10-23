-- The source departure imprint is applied after authored maps, while
-- gates lose their outside link and distant cells fade into sampled land.
local abyss = require("constants.abyss")
local harness = require("tests.harness")
local proto = require("policy.generation.abyss.proto")
local terrain = require("constants.terrain")

local test = {}

-- A real source grid supplies keyed terrain through ctx:cell. The mock
-- only fixes the departure neighborhood and the named feature roll.
function test.run()
    local ctx = {}
    local site = { level_id = 3, x = 20, y = 20 }
    local cells = {}
    local protected = {
        [abyss.CENTRE_X .. ":" .. abyss.CENTRE_Y + 1] = true,
    }

    for y = 1, abyss.HEIGHT do
        cells[y] = {}

        for x = 1, abyss.WIDTH do
            cells[y][x] = terrain.DNGN_FLOOR
        end
    end

    cells[abyss.CENTRE_Y + 2][abyss.CENTRE_X + 1] =
        terrain.DNGN_METAL_WALL

    function ctx:cell(level_id, x, y)
        harness.equal(level_id, site.level_id)

        if x == site.x and y == site.y then
            return terrain.DNGN_ENTER_ABYSS
        end

        if x == site.x + 1 and y == site.y then
            return terrain.DNGN_PERMAROCK_WALL
        end

        return terrain.DNGN_FLOOR
    end

    function ctx:random(stream, bound)
        harness.equal(stream, "abyss-features")
        harness.equal(bound, abyss.PROTO_CHANCE_SCALE)

        return 0
    end

    proto.apply(ctx, cells, site, protected)

    harness.equal(cells[abyss.CENTRE_Y + 1][abyss.CENTRE_X + 1],
        terrain.DNGN_STONE_ARCH)
    harness.equal(cells[abyss.CENTRE_Y + 1][abyss.CENTRE_X + 2],
        terrain.DNGN_ROCK_WALL)
    harness.equal(cells[abyss.CENTRE_Y + 2][abyss.CENTRE_X + 1],
        terrain.DNGN_METAL_WALL)
end

return test
