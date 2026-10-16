-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6351

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_WAR_GARGOYLE",
    status = "defined",
    name = "war gargoyle",
    glyph = 57,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_FIGHTER",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_WAR_GARGOYLE",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 13,
    average_hp_10x = 520,
    ac = 22,
    ev = 4,
    spellbook_id = "MST_SPLINTER_BREATH",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID_WINGED_TAILED",
    tile = {
        id = "TILEP_MONS_WAR_GARGOYLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 191
        {
            source_order = 122,
            min_depth = 24,
            max_depth = 27,
            rarity = 25,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
