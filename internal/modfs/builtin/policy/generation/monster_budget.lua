-- DCSS starts a new floor with three population dice. Keep this count in
-- one Lua rule so ordinary branches and the rootless Vestibule consume the
-- same saved RNG stream and use the same source branch die size.
local branches = require("ids.branches")
local die_sizes = require("constants.population_die_sizes")
local streams = require("constants.rng_streams")

local budget = {}

-- A branch may supply a numeric source die size or a named source constant.
-- The Dungeon uses ten-sided dice after D:1; an unknown name is a broken
-- catalog declaration and must not silently get a different population.
function budget.roll(ctx, branch_id, depth)
    local branch = register.get("branches", branch_id)
    local expression = branch.mon_die_size_expr
    local die_size = tonumber(expression) or die_sizes[expression]

    -- An extension branch may omit the source expression and inherit the
    -- ordinary default. A misspelled named expression remains an error.
    if expression == nil then
        die_size = die_sizes.DEFAULT_MON_DIE_SIZE
    end

    if not die_size then
        error("unknown monster die size " .. tostring(expression))
    end

    if branch_id == branches.BRANCH_DUNGEON and depth > 1 then
        die_size = die_sizes.DUNGEON_DEEP_MON_DIE_SIZE
    end

    local count = 0

    for _ = 1, 3 do
        count = count + ctx:random(streams.POPULATION_COUNT, die_size) + 1
    end

    return count
end

return budget
