-- Aizul (MONS_AIZUL) is a DCSS monster profile with 14 hit dice and speed 15.
-- Its first melee contact is AT_HIT for 25 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_AIZUL when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_AIZUL",
    status = "defined",
    name = "Aizul",
    glyph = 83,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_UNIQUE",
        "M_FEMALE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GUARDIAN_SERPENT",
    species_id = "MONS_GUARDIAN_SERPENT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- Aizul offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
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
    hd = 14,
    average_hp_10x = 1400,
    ac = 8,
    ev = 18,
    spellbook_id = "MST_AIZUL",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For Aizul, energy costs combine with speed 15 to determine action cadence,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_AIZUL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
