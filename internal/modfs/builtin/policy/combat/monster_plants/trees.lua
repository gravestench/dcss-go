-- Forest magic reads tree terrain from the level grid. It never copies
-- terrain into ECS, since a terrain change must affect every plant spell.
local terrain = require("constants.terrain")

local trees = {}

local kinds = {
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
}

-- A shared predicate keeps forest attacks and vine placement in agreement.
function trees.at(ctx, level_id, x, y)
    return kinds[ctx:cell(level_id, x, y)] == true
end

return trees
