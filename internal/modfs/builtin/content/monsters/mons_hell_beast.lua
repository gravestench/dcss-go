-- hell beast (MONS_HELL_BEAST) is a DCSS monster profile with 7 hit dice and
-- speed 15.
-- Its first melee contact is AT_BITE for 28 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_HELL_BEAST",
    status = "defined",
    name = "hell beast",
    glyph = 50,
    colour_id = "BROWN",
    flags = {
        "M_FIGHTER",
    },
    xp_modifier = 17,
    genus_id = "MONS_HELL_BEAST",
    species_id = "MONS_HELL_BEAST",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 20,
    -- hell beast offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 28,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
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
    },
    hd = 7,
    average_hp_10x = 840,
    ac = 5,
    ev = 14,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_RANDOM",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For hell beast, energy costs combine with speed 15 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_HELL_BEAST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
