-- BRANCH_SLIME ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_SLIME,
    branch_id = branches.BRANCH_SLIME,
    rows = {
        {
            monster_id = monsters.MONS_SLIME_CREATURE,
            min_depth = 1,
            max_depth = 5,
            rarity = 2000,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ACID_BLOB,
            min_depth = 1,
            max_depth = 5,
            rarity = 1000,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_AZURE_JELLY,
            min_depth = 1,
            max_depth = 5,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ROCKSLIME,
            min_depth = 1,
            max_depth = 5,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_QUICKSILVER_OOZE,
            min_depth = 1,
            max_depth = 5,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SHINING_EYE,
            min_depth = 1,
            max_depth = 5,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GOLDEN_EYE,
            min_depth = 1,
            max_depth = 5,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_EYE_OF_DEVASTATION,
            min_depth = 1,
            max_depth = 8,
            rarity = 300,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_GREAT_ORB_OF_EYES,
            min_depth = 1,
            max_depth = 8,
            rarity = 390,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_GLOWING_ORANGE_BRAIN,
            min_depth = 2,
            max_depth = 5,
            rarity = 100,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_FLOATING_EYE,
            min_depth = 2,
            max_depth = 8,
            rarity = 50,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
