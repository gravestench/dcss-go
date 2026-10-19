-- mutant beast (MONS_MUTANT_BEAST) is a DCSS monster profile with 15 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MUTANT_BEAST",
    status = "defined",
    name = "mutant beast",
    glyph = 72,
    colour_id = "MAGENTA",
    flags = {
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
    },
    xp_modifier = 11,
    genus_id = "MONS_MUTANT_BEAST",
    species_id = "MONS_MUTANT_BEAST",
    holiness = {
        "MH_NATURAL",
    },
    willpower = -3,
    -- mutant beast offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
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
    hd = 15,
    average_hp_10x = 825,
    ac = 8,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_RANDOM",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For mutant beast, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MUTANT_BEAST_BASE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_MUTANT_BEAST",
}

register.definition(categories.MONSTERS, definition)

return definition
