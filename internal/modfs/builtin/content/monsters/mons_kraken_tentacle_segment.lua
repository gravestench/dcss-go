-- tentacle segment (MONS_KRAKEN_TENTACLE_SEGMENT) is a DCSS monster profile
-- with 12 hit dice and speed 18.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_KRAKEN_TENTACLE_SEGMENT",
    status = "defined",
    name = "tentacle segment",
    glyph = 42,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_COLD_BLOOD",
        "M_NO_EXP_GAIN",
        "M_NO_THREAT",
        "M_STATIONARY",
        "M_SUBMERGES",
        "M_NO_POLY_TO",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_KRAKEN",
    species_id = "MONS_KRAKEN_TENTACLE_SEGMENT",
    holiness = {
        "MH_NATURAL",
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
    hd = 12,
    average_hp_10x = 480,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 18,
    -- For tentacle segment, energy costs combine with speed 18 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
