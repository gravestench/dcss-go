-- worldbinder (MONS_WORLDBINDER) is a DCSS monster profile with 8 hit dice
-- and speed 14.
-- Its first melee contact is AT_HIT for 8 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_WORLDBINDER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WORLDBINDER",
    status = "defined",
    name = "worldbinder",
    glyph = 120,
    colour_id = "CYAN",
    flags = {
        "M_FLIES",
    },
    xp_modifier = 13,
    genus_id = "MONS_WORLDBINDER",
    species_id = "MONS_WORLDBINDER",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 60,
    -- worldbinder offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 8,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 8,
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
    average_hp_10x = 400,
    ac = 12,
    ev = 4,
    spellbook_id = "MST_WORLDBINDER",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For worldbinder, energy costs combine with speed 14 to determine action
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_WORLDBINDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
