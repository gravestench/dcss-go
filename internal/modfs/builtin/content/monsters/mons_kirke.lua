-- Kirke (MONS_KIRKE) is a DCSS monster profile with 16 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 18 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_KIRKE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_KIRKE",
    status = "defined",
    name = "Kirke",
    glyph = 64,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FEMALE",
    },
    xp_modifier = 15,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- Kirke offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    hd = 16,
    average_hp_10x = 1120,
    ev = 10,
    spellbook_id = "MST_KIRKE",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Kirke, energy costs combine with speed 10 to determine action cadence,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_KIRKE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
