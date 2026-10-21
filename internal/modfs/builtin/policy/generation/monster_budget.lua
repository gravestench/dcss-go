-- DCSS starts a new floor with three population dice. Keep this count in
-- one Lua rule so ordinary branches and the rootless Vestibule consume the
-- same saved RNG stream and use the same source branch die size.
local branches = require("ids.branches")
local streams = require("constants.rng_streams")

local budget = {}

-- A branch may supply a numeric source die size. The Dungeon uses ten-sided
-- dice after D:1; other branches use the source default of twelve sides.
function budget.roll(ctx, branch_id, depth)
    local branch = register.get("branches", branch_id)
    local die_size = tonumber(branch.mon_die_size_expr)

    if not die_size then
        die_size = branch_id == branches.BRANCH_DUNGEON and
            depth > 1 and 10 or 12
    end

    local count = 0

    for _ = 1, 3 do
        count = count + ctx:random(streams.POPULATION_COUNT, die_size) + 1
    end

    return count
end

return budget
