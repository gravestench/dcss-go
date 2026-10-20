-- BRANCH_SHOALS ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_SHOALS,
    branch_id = branches.BRANCH_SHOALS,
    rows = {
        {
            monster_id = monsters.MONS_CENTAUR_WARRIOR,
            min_depth = 0,
            max_depth = 3,
            rarity = 89,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_FAUN,
            min_depth = 0,
            max_depth = 3,
            rarity = 355,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_WATER_NYMPH,
            min_depth = 0,
            max_depth = 6,
            rarity = 300,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_MERFOLK_AVATAR,
            min_depth = 0,
            max_depth = 6,
            rarity = 170,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_CYCLOPS,
            min_depth = 0,
            max_depth = 6,
            rarity = 110,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_KRAKEN,
            min_depth = 0,
            max_depth = 6,
            rarity = 73,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_MERFOLK_IMPALER,
            min_depth = 0,
            max_depth = 7,
            rarity = 265,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_MERFOLK_AQUAMANCER,
            min_depth = 0,
            max_depth = 7,
            rarity = 125,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_MERFOLK,
            min_depth = 1,
            max_depth = 4,
            rarity = 735,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SEA_SNAKE,
            min_depth = 1,
            max_depth = 4,
            rarity = 500,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SNAPPING_TURTLE,
            min_depth = 1,
            max_depth = 4,
            rarity = 410,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_MANTICORE,
            min_depth = 1,
            max_depth = 4,
            rarity = 510,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_MERFOLK_SIREN,
            min_depth = 1,
            max_depth = 4,
            rarity = 300,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WATER_ELEMENTAL,
            min_depth = 1,
            max_depth = 4,
            rarity = 195,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WIND_DRAKE,
            min_depth = 1,
            max_depth = 4,
            rarity = 275,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HARPY,
            min_depth = 1,
            max_depth = 4,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_MERFOLK_JAVELINEER,
            min_depth = 1,
            max_depth = 7,
            rarity = 135,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_ALLIGATOR_SNAPPING_TURTLE,
            min_depth = 1,
            max_depth = 7,
            rarity = 110,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_SATYR,
            min_depth = 2,
            max_depth = 4,
            rarity = 190,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
