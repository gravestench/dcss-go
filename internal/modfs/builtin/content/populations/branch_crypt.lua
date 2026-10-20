-- BRANCH_CRYPT ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_CRYPT,
    branch_id = branches.BRANCH_CRYPT,
    rows = {
        {
            monster_id = monsters.MONS_FLYING_SKULL,
            min_depth = -4,
            max_depth = 3,
            rarity = 45,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_NECROMANCER,
            min_depth = -4,
            max_depth = 3,
            rarity = 75,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEATH_KNIGHT,
            min_depth = -3,
            max_depth = 3,
            rarity = 75,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_WRAITH,
            min_depth = -2,
            max_depth = 3,
            rarity = 125,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_JIANGSHI,
            min_depth = -1,
            max_depth = 5,
            rarity = 75,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_PHANTASMAL_WARRIOR,
            min_depth = -1,
            max_depth = 5,
            rarity = 125,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_ANCIENT_CHAMPION,
            min_depth = -1,
            max_depth = 9,
            rarity = 120,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_FREEZING_WRAITH,
            min_depth = 0,
            max_depth = 2,
            rarity = 65,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_VAMPIRE_MAGE,
            min_depth = 0,
            max_depth = 5,
            rarity = 125,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GHOUL,
            min_depth = 0,
            max_depth = 5,
            rarity = 93,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_VAMPIRE_KNIGHT,
            min_depth = 0,
            max_depth = 5,
            rarity = 105,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SKELETAL_WARRIOR,
            min_depth = 1,
            max_depth = 4,
            rarity = 75,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SOUL_EATER,
            min_depth = 1,
            max_depth = 5,
            rarity = 55,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_EIDOLON,
            min_depth = 1,
            max_depth = 6,
            rarity = 145,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_DEATH_MAGE,
            min_depth = 1,
            max_depth = 6,
            rarity = 80,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_REVENANT,
            min_depth = 1,
            max_depth = 7,
            rarity = 85,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_CURSE_SKULL,
            min_depth = 1,
            max_depth = 7,
            rarity = 75,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_FLAYED_GHOST,
            min_depth = 2,
            max_depth = 5,
            rarity = 145,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_SHADOW_WRAITH,
            min_depth = 2,
            max_depth = 5,
            rarity = 95,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_REAPER,
            min_depth = 2,
            max_depth = 7,
            rarity = 40,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_LICH,
            min_depth = 2,
            max_depth = 7,
            rarity = 55,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_ANCIENT_LICH,
            min_depth = 3,
            max_depth = 7,
            rarity = 15,
            curve = curves.PEAK,
        },
        {
            monster_id = monsters.MONS_DREAD_LICH,
            min_depth = 3,
            max_depth = 7,
            rarity = 15,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
