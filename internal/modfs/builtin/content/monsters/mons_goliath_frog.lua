-- goliath frog (MONS_GOLIATH_FROG) is a DCSS monster profile with 12 hit dice
-- and speed 12.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GOLIATH_FROG",
    status = "defined",
    name = "goliath frog",
    glyph = 70,
    colour_id = "LIGHTGREY",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_FROG",
    species_id = "MONS_GOLIATH_FROG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- goliath frog offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_REACH_TONGUE",
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
    hd = 12,
    average_hp_10x = 420,
    ac = 3,
    ev = 16,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 12,
    -- For goliath frog, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_GOLIATH_FROG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GOLIATH_FROG",
}

register.definition(categories.MONSTERS, definition)

return definition
