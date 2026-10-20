-- BRANCH_COCYTUS ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_COCYTUS,
    branch_id = branches.BRANCH_COCYTUS,
    rows = {
        {
            monster_id = monsters.MONS_HELLION,
            min_depth = 1,
            max_depth = 7,
            rarity = 100,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELLION,
            min_depth = 8,
            max_depth = 12,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_TORMENTOR,
            min_depth = 1,
            max_depth = 7,
            rarity = 100,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TORMENTOR,
            min_depth = 8,
            max_depth = 12,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_ANCIENT_LICH,
            min_depth = 1,
            max_depth = 12,
            rarity = 10,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DREAD_LICH,
            min_depth = 1,
            max_depth = 12,
            rarity = 10,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SIMULACRUM,
            min_depth = 1,
            max_depth = 5,
            rarity = 800,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_SIMULACRUM,
            min_depth = 1,
            max_depth = 7,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FREEZING_WRAITH,
            min_depth = 1,
            max_depth = 7,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_FREEZING_WRAITH,
            min_depth = 1,
            max_depth = 7,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FROST_GIANT,
            min_depth = 1,
            max_depth = 7,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_FROST_GIANT,
            min_depth = 1,
            max_depth = 7,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TITAN,
            min_depth = 1,
            max_depth = 7,
            rarity = 200,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_AZURE_JELLY,
            min_depth = 1,
            max_depth = 7,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WENDIGO,
            min_depth = 1,
            max_depth = 7,
            rarity = 375,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_WENDIGO,
            min_depth = 7,
            max_depth = 14,
            rarity = 500,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_NARGUN,
            min_depth = 1,
            max_depth = 7,
            rarity = 375,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_NARGUN,
            min_depth = 7,
            max_depth = 14,
            rarity = 500,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_ICE_FIEND,
            min_depth = 1,
            max_depth = 7,
            rarity = 400,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_ICE_FIEND,
            min_depth = 8,
            max_depth = 14,
            rarity = 400,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SHARD_SHRIKE,
            min_depth = 1,
            max_depth = 14,
            rarity = 400,
            curve = curves.RISE,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
