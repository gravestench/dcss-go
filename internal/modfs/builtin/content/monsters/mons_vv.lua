-- Vv (MONS_VV) is a DCSS monster profile with 23 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 35 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_VV when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_VV",
    status = "defined",
    name = "Vv",
    glyph = 57,
    colour_id = "MAGENTA",
    flags = {
        "M_UNIQUE",
        "M_FEMALE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_VV",
    species_id = "MONS_VV",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 140,
    -- Vv has AT_HIT in its first attack slot; current melee rules read that slot.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_COLD",
            damage = 35,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_FIRE",
            damage = 35,
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
    hd = 23,
    average_hp_10x = 2700,
    ac = 27,
    ev = 12,
    spellbook_id = "MST_VV",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Vv, energy costs combine with speed 10 to determine action cadence, not
    -- an unconditional action each turn.
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
        id = "TILEP_MONS_VV",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
