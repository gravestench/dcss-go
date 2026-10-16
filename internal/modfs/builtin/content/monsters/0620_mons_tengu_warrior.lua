-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4245

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_TENGU_WARRIOR",
    status = "defined",
    name = "tengu warrior",
    glyph = 81,
    colour_id = "CYAN",
    flags = {
        "M_FIGHTER",
        "M_ARCHER",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 13,
    genus_id = "MONS_TENGU",
    species_id = "MONS_TENGU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_PECK",
            flavour_id = "AF_PLAIN",
            damage = 8,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 8,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 10,
    average_hp_10x = 600,
    ac = 2,
    ev = 17,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 9,
        swim = 9,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_TENGU_WARRIOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 143
        {
            source_order = 74,
            min_depth = 13,
            max_depth = 19,
            rarity = 365,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
