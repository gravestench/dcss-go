-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3198

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_SHADOW_DRAGON",
    status = "defined",
    name = "shadow dragon",
    glyph = 68,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_COLD_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_NEG",
            level = 3,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_SHADOW_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 17,
    average_hp_10x = 1275,
    ac = 15,
    ev = 10,
    spellbook_id = "MST_SHADOW_DRAGON",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SHADOW_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SHADOW_DRAGON",
    population = {
        -- Source line: 193
        {
            source_order = 124,
            min_depth = 27,
            max_depth = 27,
            rarity = 18,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
