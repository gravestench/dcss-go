-- BRANCH_TOMB ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_TOMB,
    branch_id = branches.BRANCH_TOMB,
    rows = {
        {
            monster_id = monsters.MONS_SKELETON,
            min_depth = 1,
            max_depth = 5,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ZOMBIE,
            min_depth = 1,
            max_depth = 5,
            rarity = 185,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SIMULACRUM,
            min_depth = 1,
            max_depth = 5,
            rarity = 50,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_MUMMY,
            min_depth = 1,
            max_depth = 5,
            rarity = 1000,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_FLYING_SKULL,
            min_depth = 1,
            max_depth = 5,
            rarity = 230,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GUARDIAN_MUMMY,
            min_depth = 1,
            max_depth = 5,
            rarity = 600,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_MUMMY_PRIEST,
            min_depth = -1,
            max_depth = 9,
            rarity = 335,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_ROYAL_MUMMY,
            min_depth = 4,
            max_depth = 5,
            rarity = 3,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_LICH,
            min_depth = 3,
            max_depth = 5,
            rarity = 6,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ANCIENT_LICH,
            min_depth = 3,
            max_depth = 5,
            rarity = 3,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DREAD_LICH,
            min_depth = 3,
            max_depth = 5,
            rarity = 3,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_USHABTI,
            min_depth = 1,
            max_depth = 5,
            rarity = 250,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEATH_SCARAB,
            min_depth = 1,
            max_depth = 5,
            rarity = 150,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_BENNU,
            min_depth = 3,
            max_depth = 5,
            rarity = 12,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
