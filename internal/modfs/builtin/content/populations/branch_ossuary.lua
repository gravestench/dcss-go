-- BRANCH_OSSUARY ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_OSSUARY,
    branch_id = branches.BRANCH_OSSUARY,
    rows = {
        {
            monster_id = monsters.MONS_MUMMY,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SKELETON,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ZOMBIE,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
