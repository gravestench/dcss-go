-- One Abyss visit owns its own procedural state. These tests build the
-- state through production Lua policy so starting depth, borrowed floor,
-- and source clocks cannot drift from save/restore expectations.
local abyss = require("policy.generation.abyss.state")
local branches = require("ids.branches")
local harness = require("tests.harness")
local terrain = require("constants.terrain")
local abyss_constants = require("constants.abyss")

local test = {}

-- Supply the four source state draws and two ordinary saved floors. The
-- third level is the current Abyss and must never be borrowed into itself.
local function context()
    local draws = {
        11,
        22,
        33,
        44,
    }
    local next_draw = 0
    local world = {}

    function world:random(stream, bound)
        harness.equal(stream, "abyss-state")
        harness.equal(bound, 2147483648)
        next_draw = next_draw + 1

        return draws[next_draw]
    end

    function world:level_ids()
        return { 1, 2, abyss_constants.LEVEL_ID }
    end

    function world:level_branch(id)
        return id == abyss_constants.LEVEL_ID and branches.BRANCH_ABYSS or
            branches.BRANCH_DUNGEON
    end

    function world:level_depth(id)
        return id
    end

    function world:hash_with_seed(count, seed)
        harness.equal(count, 2)
        harness.equal(seed, 33)

        return 1
    end

    function world:hash3_quotient_mod()
        return 1
    end

    function world:level_size(id)
        harness.equal(id, 2)

        return 3, 3
    end

    function world:cell(id, x, y)
        harness.equal(id, 2)

        if x == 1 and y == 1 then
            return terrain.DNGN_ROCK_WALL
        end

        return terrain.DNGN_FLOOR
    end

    return world
end

-- The pocket start is a visit with a D:1 return rule but no forged
-- banishment component. Morph depth is independent of branch depth.
function test.run()
    local state = abyss.new(context(), {
        branch_depth = 1,
        pocket_start = true,
    })

    harness.equal(state.branch_depth, 1)
    harness.equal(state.morph_depth, 44)
    harness.equal(state.phase, 0)
    harness.equal(state.world_x, 11)
    harness.equal(state.world_y, 22)
    harness.equal(state.terrain_seed, 33)
    harness.equal(state.borrowed_level_id, 2)
    harness.equal(state.borrowed_layout[2][2],
        terrain.DNGN_ROCK_WALL)
    harness.equal(state.exit_xp, 10)
    harness.equal(state.min_branch_depth, 1)
    harness.truthy(state.pocket_start)
    harness.equal(#state.sample_queue, 0)
end

return test
