-- BRANCH_ZOT ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_ZOT,
    branch_id = branches.BRANCH_ZOT,
    rows = {
        {
            monster_id = monsters.MONS_MOTH_OF_WRATH,
            min_depth = 1,
            max_depth = 5,
            rarity = 970,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GHOST_MOTH,
            min_depth = 1,
            max_depth = 5,
            rarity = 192,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_BLACK_DRACONIAN,
            min_depth = 1,
            max_depth = 5,
            rarity = 113,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_YELLOW_DRACONIAN,
            min_depth = 1,
            max_depth = 5,
            rarity = 113,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GREEN_DRACONIAN,
            min_depth = 1,
            max_depth = 5,
            rarity = 113,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_PURPLE_DRACONIAN,
            min_depth = 1,
            max_depth = 5,
            rarity = 113,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_RED_DRACONIAN,
            min_depth = 1,
            max_depth = 5,
            rarity = 113,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WHITE_DRACONIAN,
            min_depth = 1,
            max_depth = 5,
            rarity = 113,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DRACONIAN_STORMCALLER,
            min_depth = 1,
            max_depth = 5,
            rarity = 70,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DRACONIAN_MONK,
            min_depth = 1,
            max_depth = 5,
            rarity = 70,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DRACONIAN_SHIFTER,
            min_depth = 1,
            max_depth = 5,
            rarity = 70,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DRACONIAN_ANNIHILATOR,
            min_depth = 1,
            max_depth = 5,
            rarity = 70,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DRACONIAN_KNIGHT,
            min_depth = 1,
            max_depth = 5,
            rarity = 70,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DRACONIAN_SCORCHER,
            min_depth = 1,
            max_depth = 5,
            rarity = 70,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_QUICKSILVER_DRAGON,
            min_depth = 1,
            max_depth = 5,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SHADOW_DRAGON,
            min_depth = 1,
            max_depth = 5,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_STORM_DRAGON,
            min_depth = -4,
            max_depth = 5,
            rarity = 515,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_GOLDEN_DRAGON,
            min_depth = 1,
            max_depth = 11,
            rarity = 365,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_KILLER_KLOWN,
            min_depth = 2,
            max_depth = 8,
            rarity = 52,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEATH_COB,
            min_depth = 1,
            max_depth = 5,
            rarity = 335,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_CURSE_TOE,
            min_depth = 1,
            max_depth = 5,
            rarity = 150,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_TENTACLED_MONSTROSITY,
            min_depth = 1,
            max_depth = 5,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ELECTRIC_GOLEM,
            min_depth = 1,
            max_depth = 5,
            rarity = 89,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_ORB_OF_FIRE,
            min_depth = 1,
            max_depth = 5,
            rarity = 42,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
