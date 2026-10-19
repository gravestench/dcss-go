-- Orb Guardian (MONS_ORB_GUARDIAN) is a DCSS monster profile with 15 hit dice
-- and speed 14.
-- Its first melee contact is AT_HIT for 45 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ORB_GUARDIAN",
    status = "defined",
    name = "Orb Guardian",
    glyph = 88,
    colour_id = "MAGENTA",
    flags = {
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_NO_POLY_TO",
    },
    xp_modifier = 20,
    genus_id = "MONS_ORB_GUARDIAN",
    species_id = "MONS_ORB_GUARDIAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- Orb Guardian offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 45,
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
    hd = 15,
    average_hp_10x = 825,
    ac = 13,
    ev = 13,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For Orb Guardian, energy costs combine with speed 14 to determine action
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_ORB_GUARDIAN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
