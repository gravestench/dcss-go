-- floating eye (MONS_FLOATING_EYE) is a DCSS monster profile with 9 hit dice
-- and speed 10.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- The AI consults MST_FLOATING_EYE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_FLOATING_EYE",
    status = "defined",
    name = "floating eye",
    glyph = 71,
    colour_id = "WHITE",
    flags = {
        "M_SEE_INVIS",
        "M_FLIES",
        "M_NO_SKELETON",
    },
    xp_modifier = 6,
    genus_id = "MONS_FLOATING_EYE",
    species_id = "MONS_FLOATING_EYE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
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
    hd = 9,
    average_hp_10x = 165,
    ev = 1,
    spellbook_id = "MST_FLOATING_EYE",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For floating eye, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_ORB",
    tile = {
        id = "TILEP_MONS_FLOATING_EYE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
