-- knight (MONS_ANCESTOR_KNIGHT) is a DCSS monster profile with 1 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ANCESTOR_KNIGHT",
    status = "defined",
    name = "knight",
    glyph = 82,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_ANCESTOR",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
        "M_FLIES",
        "M_FAST_REGEN",
        "M_INSUBSTANTIAL",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 1,
    genus_id = "MONS_ANCESTOR",
    species_id = "MONS_ANCESTOR_KNIGHT",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = -5,
    -- knight offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 27,
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
    average_hp_10x = 1,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For knight, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ANCESTOR_KNIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
