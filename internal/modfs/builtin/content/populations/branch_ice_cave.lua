-- BRANCH_ICE_CAVE ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_ICE_CAVE,
    branch_id = branches.BRANCH_ICE_CAVE,
    rows = {
        {
            monster_id = monsters.MONS_YAK,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_POLAR_BEAR,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ICE_BEAST,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WHITE_IMP,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ICE_DEVIL,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_RIME_DRAKE,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FREEZING_WRAITH,
            min_depth = 1,
            max_depth = 1,
            rarity = 260,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SIMULACRUM,
            min_depth = 1,
            max_depth = 1,
            rarity = 1030,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
