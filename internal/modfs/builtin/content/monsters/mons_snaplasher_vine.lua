-- snaplasher vine (MONS_SNAPLASHER_VINE) is a DCSS monster profile with 12
-- hit dice and speed 13.
-- Its first melee contact is AT_CONSTRICT for 0 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SNAPLASHER_VINE",
    status = "defined",
    name = "snaplasher vine",
    glyph = 119,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_NO_EXP_GAIN",
        "M_STATIONARY",
        "M_NO_POLY_TO",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_PLANT",
    species_id = "MONS_SNAPLASHER_VINE",
    holiness = {
        "MH_PLANT",
    },
    willpower = 40,
    -- snaplasher vine offers AT_CONSTRICT as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 0,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 14,
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
    average_hp_10x = 240,
    ac = 4,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For snaplasher vine, energy costs combine with speed 13 to determine action
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
