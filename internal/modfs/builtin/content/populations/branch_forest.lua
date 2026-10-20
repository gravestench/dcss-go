-- BRANCH_FOREST ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_FOREST,
    branch_id = branches.BRANCH_FOREST,
    rows = {
        {
            monster_id = monsters.MONS_WOLF,
            min_depth = 1,
            max_depth = 5,
            rarity = 120,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_BLACK_BEAR,
            min_depth = 1,
            max_depth = 5,
            rarity = 35,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_YAK,
            min_depth = 1,
            max_depth = 5,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DIRE_ELEPHANT,
            min_depth = 1,
            max_depth = 7,
            rarity = 145,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_HORNET,
            min_depth = 1,
            max_depth = 5,
            rarity = 45,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_REDBACK,
            min_depth = 1,
            max_depth = 6,
            rarity = 75,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_WOLF_SPIDER,
            min_depth = 2,
            max_depth = 7,
            rarity = 35,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_OKLOB_PLANT,
            min_depth = 1,
            max_depth = 9,
            rarity = 75,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DRYAD,
            min_depth = 1,
            max_depth = 5,
            rarity = 170,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WIND_DRAKE,
            min_depth = 1,
            max_depth = 5,
            rarity = 120,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FAUN,
            min_depth = -1,
            max_depth = 5,
            rarity = 75,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SATYR,
            min_depth = 0,
            max_depth = 9,
            rarity = 105,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SPRIGGAN_DRUID,
            min_depth = 2,
            max_depth = 8,
            rarity = 55,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SPRIGGAN_RIDER,
            min_depth = 1,
            max_depth = 6,
            rarity = 155,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SPRIGGAN_BERSERKER,
            min_depth = 1,
            max_depth = 9,
            rarity = 235,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SPRIGGAN_AIR_MAGE,
            min_depth = 1,
            max_depth = 8,
            rarity = 155,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SPRIGGAN_DEFENDER,
            min_depth = 3,
            max_depth = 5,
            rarity = 115,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_APIS,
            min_depth = 1,
            max_depth = 7,
            rarity = 85,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_SHAMBLING_MANGROVE,
            min_depth = 2,
            max_depth = 7,
            rarity = 165,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_ANACONDA,
            min_depth = 1,
            max_depth = 6,
            rarity = 85,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_THORN_HUNTER,
            min_depth = 1,
            max_depth = 9,
            rarity = 100,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_BUTTERFLY,
            min_depth = 1,
            max_depth = 5,
            rarity = 125,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
