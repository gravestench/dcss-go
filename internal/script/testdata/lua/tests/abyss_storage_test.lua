-- The session reserves the one stable Abyss level ID before any visit.
-- Its terrain is a backing grid; entry policy replaces it atomically
-- with a source-sampled region when the first actor is banished.
local abyss = require("policy.generation.abyss")
local constants = require("constants.abyss")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- Reserve a complete typed grid so structural commands have an owner
-- without drawing a source world coordinate during ordinary startup.
function test.run()
    local level = abyss.storage()

    harness.equal(level.id, constants.LEVEL_ID)
    harness.equal(#level.cells, constants.HEIGHT)
    harness.equal(#level.cells[1], constants.WIDTH)
    harness.equal(level.cells[1][1], terrain.DNGN_ROCK_WALL)
    harness.equal(level.cells[36][41], terrain.DNGN_FLOOR)
    harness.equal(level.initial_monsters, 0)
end

return test
