-- BRANCH_DWARF ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_DWARF,
    branch_id = branches.BRANCH_DWARF,
    rows = {
        {
            monster_id = monsters.MONS_DEEP_DWARF,
            min_depth = 1,
            max_depth = 1,
            rarity = 1000,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEATH_KNIGHT,
            min_depth = 1,
            max_depth = 1,
            rarity = 690,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_TROLL,
            min_depth = 1,
            max_depth = 1,
            rarity = 3,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_TROLL_EARTH_MAGE,
            min_depth = 1,
            max_depth = 1,
            rarity = 3,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_TROLL_SHAMAN,
            min_depth = 1,
            max_depth = 1,
            rarity = 3,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_STONE_GIANT,
            min_depth = 1,
            max_depth = 1,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FIRE_GIANT,
            min_depth = 1,
            max_depth = 1,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FROST_GIANT,
            min_depth = 1,
            max_depth = 1,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WRAITH,
            min_depth = 1,
            max_depth = 1,
            rarity = 192,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SHADOW_WRAITH,
            min_depth = 1,
            max_depth = 1,
            rarity = 3,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_EIDOLON,
            min_depth = 1,
            max_depth = 1,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_PHANTASMAL_WARRIOR,
            min_depth = 1,
            max_depth = 1,
            rarity = 8,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
