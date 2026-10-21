-- A mod replaces one whole-floor DES file and keeps the matching bundled
-- Lua hook. Neither the layout catalog nor Go registers the new bytes.
local branches = require("ids.branches")
local harness = require("tests.harness")
local layouts = require("policy.generation.layouts.catalog")
local names = require("constants.slime_pit")

local test = {}

-- Execute through the ordinary catalog so the test covers effective VFS
-- discovery, source-position hook lookup, and the shared stair postpass.
function test.run()
    local definition = layouts.get(names.MAP_ID)

    harness.equal(#definition.rows, 6, "mod replaced the bundled Slime map")

    local state = 31
    local ctx = {}

    function ctx:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    local floor = layouts.execute(ctx, definition,
        branches.BRANCH_SLIME, 5, {
            up = 1,
            down = 0,
        })

    harness.equal(floor.id, names.MAP_ID,
        "modded end kept the stable layout ID")
end

return test
