-- BRANCH_DESOLATION ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_DESOLATION,
    branch_id = branches.BRANCH_DESOLATION,
    rows = {
        {
            monster_id = monsters.MONS_SALTLING,
            min_depth = 1,
            max_depth = 1,
            rarity = 1200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DANCING_WEAPON,
            min_depth = 1,
            max_depth = 1,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_MOLTEN_GARGOYLE,
            min_depth = 1,
            max_depth = 1,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_CRYSTAL_GUARDIAN,
            min_depth = 1,
            max_depth = 1,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_IMPERIAL_MYRMIDON,
            min_depth = 1,
            max_depth = 1,
            rarity = 50,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
