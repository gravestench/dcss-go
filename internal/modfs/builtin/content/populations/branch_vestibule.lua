-- BRANCH_VESTIBULE ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_VESTIBULE,
    branch_id = branches.BRANCH_VESTIBULE,
    rows = {
        {
            monster_id = monsters.MONS_HELL_RAT,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_DEMONIC_CRAWLER,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELL_HOUND,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELL_HOG,
            min_depth = 1,
            max_depth = 1,
            rarity = 136,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELL_KNIGHT,
            min_depth = 1,
            max_depth = 1,
            rarity = 136,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_NECROMANCER,
            min_depth = 1,
            max_depth = 1,
            rarity = 136,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELLEPHANT,
            min_depth = 1,
            max_depth = 1,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TENTACLED_MONSTROSITY,
            min_depth = 1,
            max_depth = 1,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_RED_DEVIL,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_ICE_DEVIL,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SUN_DEMON,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SOUL_EATER,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_REAPER,
            min_depth = 1,
            max_depth = 1,
            rarity = 515,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_LOROCYPROCA,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_HELLION,
            min_depth = 1,
            max_depth = 1,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TORMENTOR,
            min_depth = 1,
            max_depth = 1,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_RUST_DEVIL,
            min_depth = 1,
            max_depth = 1,
            rarity = 89,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_GREEN_DEATH,
            min_depth = 1,
            max_depth = 1,
            rarity = 52,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_BLIZZARD_DEMON,
            min_depth = 1,
            max_depth = 1,
            rarity = 52,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_BALRUG,
            min_depth = 1,
            max_depth = 1,
            rarity = 52,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_CACODEMON,
            min_depth = 1,
            max_depth = 1,
            rarity = 52,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
