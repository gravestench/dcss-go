-- BRANCH_ELF ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_ELF,
    branch_id = branches.BRANCH_ELF,
    rows = {
        {
            monster_id = monsters.MONS_ORC_HIGH_PRIEST,
            min_depth = 1,
            max_depth = 5,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ORC_SORCERER,
            min_depth = 1,
            max_depth = 6,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_AIR_MAGE,
            min_depth = 1,
            max_depth = 7,
            rarity = 1385,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_FIRE_MAGE,
            min_depth = 1,
            max_depth = 7,
            rarity = 1385,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DANCING_WEAPON,
            min_depth = 1,
            max_depth = 7,
            rarity = 1385,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_KNIGHT,
            min_depth = 1,
            max_depth = 7,
            rarity = 925,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_ARCHER,
            min_depth = 1,
            max_depth = 7,
            rarity = 925,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FIRE_ELEMENTAL,
            min_depth = 1,
            max_depth = 7,
            rarity = 345,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_WATER_ELEMENTAL,
            min_depth = 1,
            max_depth = 7,
            rarity = 345,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_AIR_ELEMENTAL,
            min_depth = 1,
            max_depth = 7,
            rarity = 345,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_EARTH_ELEMENTAL,
            min_depth = 1,
            max_depth = 7,
            rarity = 345,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_SORCERER,
            min_depth = 1,
            max_depth = 8,
            rarity = 65,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_ANNIHILATOR,
            min_depth = 1,
            max_depth = 7,
            rarity = 40,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_DEMONOLOGIST,
            min_depth = 1,
            max_depth = 8,
            rarity = 65,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_HIGH_PRIEST,
            min_depth = 1,
            max_depth = 7,
            rarity = 40,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_ELEMENTALIST,
            min_depth = 1,
            max_depth = 8,
            rarity = 65,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_DEATH_MAGE,
            min_depth = 0,
            max_depth = 7,
            rarity = 45,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_BLADEMASTER,
            min_depth = 6,
            max_depth = 7,
            rarity = 10,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_DEEP_ELF_MASTER_ARCHER,
            min_depth = 6,
            max_depth = 7,
            rarity = 10,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_SHAPESHIFTER,
            min_depth = 1,
            max_depth = 6,
            rarity = 150,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GLOWING_SHAPESHIFTER,
            min_depth = 1,
            max_depth = 6,
            rarity = 65,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
