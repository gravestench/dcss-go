-- Arachne (MONS_ARACHNE) is a DCSS monster profile with 17 hit dice and speed
-- 15.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ARACHNE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ARACHNE",
    status = "defined",
    name = "Arachne",
    glyph = 72,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
        "M_FEMALE",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_SPIDER",
    species_id = "MONS_ARACHNE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- Arachne offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    hd = 17,
    average_hp_10x = 2040,
    ac = 3,
    ev = 10,
    spellbook_id = "MST_ARACHNE",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For Arachne, energy costs combine with speed 15 to determine action cadence,
    -- not an unconditional action each turn.
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_ARACHNE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ARACHNE",
}

register.definition(categories.MONSTERS, definition)

return definition
