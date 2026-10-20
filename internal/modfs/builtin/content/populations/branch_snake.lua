-- BRANCH_SNAKE ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_SNAKE,
    branch_id = branches.BRANCH_SNAKE,
    rows = {
        {
            monster_id = monsters.MONS_NAGA,
            min_depth = -4,
            max_depth = 4,
            rarity = 750,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SALAMANDER,
            min_depth = 0,
            max_depth = 4,
            rarity = 215,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_ANACONDA,
            min_depth = 0,
            max_depth = 6,
            rarity = 315,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_BLACK_MAMBA,
            min_depth = 0,
            max_depth = 8,
            rarity = 1125,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_NAGA_WARRIOR,
            min_depth = 0,
            max_depth = 8,
            rarity = 340,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_NAGA_MAGE,
            min_depth = 0,
            max_depth = 8,
            rarity = 550,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_NAGA_RITUALIST,
            min_depth = 0,
            max_depth = 8,
            rarity = 225,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_NAGA_SHARPSHOOTER,
            min_depth = 0,
            max_depth = 8,
            rarity = 315,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SHOCK_SERPENT,
            min_depth = 0,
            max_depth = 8,
            rarity = 415,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_MANA_VIPER,
            min_depth = 1,
            max_depth = 4,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GUARDIAN_SERPENT,
            min_depth = 1,
            max_depth = 7,
            rarity = 225,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_SALAMANDER_MYSTIC,
            min_depth = 2,
            max_depth = 5,
            rarity = 110,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_NAGARAJA,
            min_depth = 2,
            max_depth = 8,
            rarity = 145,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SALAMANDER_TYRANT,
            min_depth = 2,
            max_depth = 8,
            rarity = 100,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
