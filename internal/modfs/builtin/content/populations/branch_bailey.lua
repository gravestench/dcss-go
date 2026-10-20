-- BRANCH_BAILEY ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_BAILEY,
    branch_id = branches.BRANCH_BAILEY,
    rows = {
        {
            monster_id = monsters.MONS_GNOLL,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_WARRIOR,
            min_depth = 1,
            max_depth = 1,
            rarity = 260,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_KNIGHT,
            min_depth = 1,
            max_depth = 1,
            rarity = 25,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
