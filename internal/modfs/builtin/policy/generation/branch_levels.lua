-- Branch floor IDs are stable because the committed branch catalog supplies
-- numeric IDs. A local depth is explicit; callers never decode it from a
-- grid coordinate, a Lua file name, or another branch's floor number.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

local levels = {}

-- Dungeon keeps its historical 1..15 IDs. Other ordinary branches occupy
-- a nonoverlapping hundred-wide range from their source numeric ID.
function levels.id(branch_id, local_depth)
    local branch = catalog.get(categories.BRANCHES, branch_id)

    if type(local_depth) ~= "number" or local_depth % 1 ~= 0 or
        local_depth < 1 or local_depth > branch.depth then
        error("invalid local depth " .. tostring(local_depth) ..
            " for " .. tostring(branch_id))
    end

    if type(branch.numeric_id) ~= "number" or
        branch.numeric_id < 0 or branch.numeric_id % 1 ~= 0 then
        error("branch " .. branch_id .. " has no numeric ID")
    end

    local id = branch.numeric_id * 100 + local_depth

    if branch_id == branches.BRANCH_DUNGEON then
        return local_depth
    end

    return id
end

return levels
