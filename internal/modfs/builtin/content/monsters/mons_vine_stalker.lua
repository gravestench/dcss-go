-- vine stalker (MONS_VINE_STALKER) is a DCSS monster profile with 8 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 10 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_VINE_STALKER",
    status = "defined",
    name = "vine stalker",
    glyph = 102,
    colour_id = "GREEN",
    flags = {
        "M_SPEAKS",
        "M_NO_POLY_TO",
        "M_FAST_REGEN",
        "M_NO_SKELETON",
    },
    xp_modifier = 10,
    genus_id = "MONS_VINE_STALKER",
    species_id = "MONS_VINE_STALKER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- vine stalker offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_ANTIMAGIC",
            damage = 10,
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
    average_hp_10x = 360,
    ac = 2,
    ev = 12,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For vine stalker, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_VINE_STALKER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
