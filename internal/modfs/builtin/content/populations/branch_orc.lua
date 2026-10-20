-- BRANCH_ORC ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")
local sentinels = require("constants.population_sentinels")

local definition = {
    id = branches.BRANCH_ORC,
    branch_id = branches.BRANCH_ORC,
    rows = {
        {
            monster_id = sentinels.NO_MONSTER,
            min_depth = 1,
            max_depth = 4,
            rarity = 384,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_WARRIOR,
            min_depth = 1,
            max_depth = 4,
            rarity = 192,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_PRIEST,
            min_depth = 1,
            max_depth = 4,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_WIZARD,
            min_depth = 1,
            max_depth = 4,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_KNIGHT,
            min_depth = 1,
            max_depth = 4,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_HIGH_PRIEST,
            min_depth = 1,
            max_depth = 4,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_SORCERER,
            min_depth = 1,
            max_depth = 4,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_WARLORD,
            min_depth = 1,
            max_depth = 4,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WARG,
            min_depth = 1,
            max_depth = 4,
            rarity = 40,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GNOLL,
            min_depth = 1,
            max_depth = 4,
            rarity = 3,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GNOLL_BOUDA,
            min_depth = 1,
            max_depth = 4,
            rarity = 2,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GNOLL_SERGEANT,
            min_depth = 1,
            max_depth = 4,
            rarity = 1,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_OGRE,
            min_depth = 1,
            max_depth = 4,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TWO_HEADED_OGRE,
            min_depth = 1,
            max_depth = 4,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_OGRE_MAGE,
            min_depth = 1,
            max_depth = 4,
            rarity = 1,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TROLL,
            min_depth = 1,
            max_depth = 4,
            rarity = 40,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_CYCLOPS,
            min_depth = 1,
            max_depth = 4,
            rarity = 8,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ETTIN,
            min_depth = 1,
            max_depth = 4,
            rarity = 4,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_STONE_GIANT,
            min_depth = 3,
            max_depth = 4,
            rarity = 4,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
