-- BRANCH_DIS ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_DIS,
    branch_id = branches.BRANCH_DIS,
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
            monster_id = monsters.MONS_ANCIENT_CHAMPION,
            min_depth = 1,
            max_depth = 5,
            rarity = 500,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_ANCIENT_CHAMPION,
            min_depth = 1,
            max_depth = 7,
            rarity = 125,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WAR_GARGOYLE,
            min_depth = 1,
            max_depth = 5,
            rarity = 400,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_WAR_GARGOYLE,
            min_depth = 1,
            max_depth = 7,
            rarity = 100,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_IRON_DRAGON,
            min_depth = 1,
            max_depth = 5,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_IRON_DRAGON,
            min_depth = 1,
            max_depth = 7,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_IRON_GOLEM,
            min_depth = 1,
            max_depth = 7,
            rarity = 300,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_IRON_GOLEM,
            min_depth = 7,
            max_depth = 14,
            rarity = 300,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_CAUSTIC_SHRIKE,
            min_depth = 1,
            max_depth = 7,
            rarity = 200,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_CAUSTIC_SHRIKE,
            min_depth = 7,
            max_depth = 14,
            rarity = 200,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_QUICKSILVER_ELEMENTAL,
            min_depth = 1,
            max_depth = 7,
            rarity = 300,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_QUICKSILVER_ELEMENTAL,
            min_depth = 7,
            max_depth = 14,
            rarity = 300,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_CRYSTAL_ECHIDNA,
            min_depth = 1,
            max_depth = 7,
            rarity = 200,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_CRYSTAL_ECHIDNA,
            min_depth = 7,
            max_depth = 14,
            rarity = 200,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_HELL_SENTINEL,
            min_depth = 1,
            max_depth = 7,
            rarity = 400,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_HELL_SENTINEL,
            min_depth = 8,
            max_depth = 14,
            rarity = 400,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_IRON_GIANT,
            min_depth = 1,
            max_depth = 14,
            rarity = 400,
            curve = curves.RISE,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
