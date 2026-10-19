-- oklob sapling (MONS_OKLOB_SAPLING) is a DCSS monster profile with 4 hit
-- dice and speed 10.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- The AI consults MST_OKLOB_SAPLING when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_OKLOB_SAPLING",
    status = "defined",
    name = "oklob sapling",
    glyph = 80,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_STATIONARY",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ACID",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_PLANT",
    species_id = "MONS_OKLOB_PLANT",
    holiness = {
        "MH_PLANT",
    },
    willpower = 20,
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
    hd = 4,
    average_hp_10x = 220,
    ac = 10,
    spellbook_id = "MST_OKLOB_SAPLING",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For oklob sapling, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_PLANT",
    tile = {
        id = "TILEP_MONS_OKLOB_SAPLING",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
