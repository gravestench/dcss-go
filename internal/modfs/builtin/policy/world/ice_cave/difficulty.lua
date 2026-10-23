-- The source entrance chooses its cave variant from its outside floor.
-- Generation and save validation share this rule so a changed marker and
-- ECS clock cannot together turn an easy D:13 gate into a hard one.
local branches = require("ids.branches")
local ice_cave = require("constants.ice_cave")

local difficulty = {}

-- Lair and Orc stay easy; Dungeon changes at D:14. Other source-eligible
-- branches use the hard variant. Eligibility itself belongs to the vault.
function difficulty.hard(branch_id, depth)
    if branch_id == branches.BRANCH_LAIR or
        branch_id == branches.BRANCH_ORC then
        return false
    end

    if branch_id == branches.BRANCH_DUNGEON and
        depth < ice_cave.HARD_DUNGEON_DEPTH then
        return false
    end

    return true
end

return difficulty
