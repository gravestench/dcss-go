-- A borrowed ordinary floor is a texture, never another live level.
-- Portals and stairs therefore lose their travel effects before the
-- Abyss saves the copy, and dense walls erode into procedural fallback.
local borrowed = require("policy.generation.abyss.borrowed")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- The fixture makes a solid centre surrounded by eight solid cells.
-- That centre must become nil, which asks the river layout to fill it.
function test.run()
    local rows = {
        {
            terrain.DNGN_ROCK_WALL,
            terrain.DNGN_ROCK_WALL,
            terrain.DNGN_ROCK_WALL,
        },
        {
            terrain.DNGN_ROCK_WALL,
            terrain.DNGN_EXIT_BAZAAR,
            terrain.DNGN_ROCK_WALL,
        },
        {
            terrain.DNGN_ROCK_WALL,
            terrain.DNGN_ROCK_WALL,
            terrain.DNGN_ROCK_WALL,
        },
    }
    local context = {
        hash3_quotient_mod = function()
            return 1
        end,
    }
    local prepared = borrowed.prepare(context, rows)

    harness.equal(prepared[2][2], terrain.DNGN_UNSEEN)
    harness.equal(borrowed.sanitize(terrain.DNGN_EXIT_BAZAAR),
        terrain.DNGN_STONE_ARCH)
    harness.equal(borrowed.sanitize(terrain.DNGN_STONE_STAIRS_UP_I),
        terrain.DNGN_FLOOR)
end

return test
