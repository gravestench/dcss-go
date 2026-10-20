-- BRANCH_SEWER ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_SEWER,
    branch_id = branches.BRANCH_SEWER,
    rows = {
        {
            monster_id = monsters.MONS_FRILLED_LIZARD,
            min_depth = 1,
            max_depth = 1,
            rarity = 1000,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_QUOKKA,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_BAT,
            min_depth = 1,
            max_depth = 1,
            rarity = 1000,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_BALL_PYTHON,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ADDER,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WORM,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ENDOPLASM,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GIANT_COCKROACH,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
