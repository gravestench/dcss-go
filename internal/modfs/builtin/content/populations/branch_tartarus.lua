-- BRANCH_TARTARUS ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = branches.BRANCH_TARTARUS,
    branch_id = branches.BRANCH_TARTARUS,
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
            monster_id = monsters.MONS_SPECTRAL_THING,
            min_depth = 1,
            max_depth = 5,
            rarity = 800,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_SPECTRAL_THING,
            min_depth = 1,
            max_depth = 7,
            rarity = 200,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_SHADOW_WRAITH,
            min_depth = 1,
            max_depth = 5,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_SHADOW_WRAITH,
            min_depth = 1,
            max_depth = 7,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_EIDOLON,
            min_depth = 1,
            max_depth = 5,
            rarity = 100,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_EIDOLON,
            min_depth = 1,
            max_depth = 7,
            rarity = 25,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_PROFANE_SERVITOR,
            min_depth = 1,
            max_depth = 7,
            rarity = 200,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_BONE_DRAGON,
            min_depth = 1,
            max_depth = 7,
            rarity = 150,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_BONE_DRAGON,
            min_depth = 7,
            max_depth = 14,
            rarity = 400,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_DOOM_HOUND,
            min_depth = 1,
            max_depth = 7,
            rarity = 300,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_DOOM_HOUND,
            min_depth = 7,
            max_depth = 14,
            rarity = 300,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_PUTRID_MOUTH,
            min_depth = 1,
            max_depth = 7,
            rarity = 300,
            curve = curves.SEMI,
        },
        {
            monster_id = monsters.MONS_PUTRID_MOUTH,
            min_depth = 7,
            max_depth = 14,
            rarity = 300,
            curve = curves.FALL,
        },
        {
            monster_id = monsters.MONS_SILENT_SPECTRE,
            min_depth = 1,
            max_depth = 12,
            rarity = 50,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TAINTED_LEVIATHAN,
            min_depth = 1,
            max_depth = 7,
            rarity = 400,
            curve = curves.RISE,
        },
        {
            monster_id = monsters.MONS_TAINTED_LEVIATHAN,
            min_depth = 8,
            max_depth = 14,
            rarity = 400,
            curve = curves.FLAT,
        },
        {
            monster_id = monsters.MONS_TZITZIMITL,
            min_depth = 1,
            max_depth = 14,
            rarity = 400,
            curve = curves.RISE,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
