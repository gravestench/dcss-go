-- steelbarb worm (MONS_STEELBARB_WORM) is a DCSS monster profile with 10 hit
-- dice and speed 12.
-- Its first melee contact is AT_HIT for 29 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_STEELBARB_WORM",
    status = "defined",
    name = "steelbarb worm",
    glyph = 119,
    colour_id = "LIGHTGRAY",
    flags = {
        "M_NO_SKELETON",
        "M_FAST_REGEN",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
    },
    xp_modifier = 8,
    genus_id = "MONS_WORM",
    species_id = "MONS_STEELBARB_WORM",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- steelbarb worm offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_BARBS",
            damage = 29,
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
    hd = 10,
    average_hp_10x = 690,
    ac = 11,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For steelbarb worm, energy costs combine with speed 12 to determine action
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_STEELBARB_WORM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_STEELBARB_WORM",
}

register.definition(categories.MONSTERS, definition)

return definition
