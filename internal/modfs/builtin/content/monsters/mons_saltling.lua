-- saltling (MONS_SALTLING) is a DCSS monster profile with 8 hit dice and
-- speed 12.
-- Its first melee contact is AT_HIT for 20 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SALTLING",
    status = "defined",
    name = "saltling",
    glyph = 57,
    colour_id = "WHITE",
    xp_modifier = 10,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_SALTLING",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- saltling offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 8,
    average_hp_10x = 270,
    ac = 15,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For saltling, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_SALTLING",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
