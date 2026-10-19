-- ghost (MONS_GHOST) is a DCSS monster profile with 1 hit dice and speed 10.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GHOST",
    status = "defined",
    name = "ghost",
    glyph = 87,
    colour_id = "WHITE",
    flags = {
        "M_INSUBSTANTIAL",
        "M_NO_POLY_TO",
        "M_FLIES",
    },
    genus_id = "MONS_GHOST",
    species_id = "MONS_GHOST",
    holiness = {
        "MH_UNDEAD",
    },
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
    hd = 1,
    average_hp_10x = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For ghost, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_GHOST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
