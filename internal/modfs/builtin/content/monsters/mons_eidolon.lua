-- eidolon (MONS_EIDOLON) is a DCSS monster profile with 13 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_EIDOLON when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_EIDOLON",
    status = "defined",
    name = "eidolon",
    glyph = 87,
    colour_id = "BROWN",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_EIDOLON",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 140,
    -- eidolon offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN_SPEED",
            damage = 27,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN_STAT",
            damage = 17,
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
    hd = 13,
    average_hp_10x = 715,
    ac = 12,
    ev = 10,
    spellbook_id = "MST_EIDOLON",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For eidolon, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_EIDOLON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
