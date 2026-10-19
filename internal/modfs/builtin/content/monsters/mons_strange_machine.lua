-- strange machine (MONS_STRANGE_MACHINE) is a DCSS monster profile with 21
-- hit dice and speed 10.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- The AI consults MST_STRANGE_MACHINE when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_STRANGE_MACHINE",
    status = "defined",
    name = "strange machine",
    glyph = 56,
    colour_id = "ETC_SILVER",
    flags = {
        "M_STATIONARY",
        "M_NO_POLY_TO",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_STRANGE_MACHINE",
    species_id = "MONS_STRANGE_MACHINE",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- AT_NONE leaves the first attack slot empty; it is not a melee contact.
    attacks = {
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 21,
    average_hp_10x = 900,
    ac = 12,
    ev = 1,
    spellbook_id = "MST_STRANGE_MACHINE",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For strange machine, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_STRANGE_MACHINE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
