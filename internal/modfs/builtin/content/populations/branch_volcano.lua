-- BRANCH_VOLCANO ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_VOLCANO,
    branch_id = branches.BRANCH_VOLCANO,
    rows = {
        {
            monster_id = monsters.MONS_SALAMANDER,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELL_HOUND,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_RED_DEVIL,
            min_depth = 1,
            max_depth = 1,
            rarity = 385,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_EFREET,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_LINDWURM,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TOENAIL_GOLEM,
            min_depth = 1,
            max_depth = 1,
            rarity = 255,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FIRE_ELEMENTAL,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GARGOYLE,
            min_depth = 1,
            max_depth = 1,
            rarity = 385,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_MOLTEN_GARGOYLE,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
