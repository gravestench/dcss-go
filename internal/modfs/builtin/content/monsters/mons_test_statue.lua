-- test statue (MONS_TEST_STATUE) is a DCSS monster profile with 1000 hit dice
-- and speed 14.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TEST_STATUE",
    status = "defined",
    name = "test statue",
    glyph = 88,
    colour_id = "WHITE",
    flags = {
        "M_STATIONARY",
        "M_NO_POLY_TO",
        "M_FAST_REGEN",
        "M_NO_THREAT",
    },
    xp_modifier = 15,
    genus_id = "MONS_TEST_STATUE",
    species_id = "MONS_TEST_STATUE",
    holiness = {
        "MH_NONLIVING",
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
    hd = 1000,
    average_hp_10x = 10000000,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 14,
    -- For test statue, energy costs combine with speed 14 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
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
        id = "TILEP_MONS_TEST_SPAWNER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
