-- Dispater (MONS_DISPATER) is a DCSS monster profile with 16 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 50 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_DISPATER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DISPATER",
    status = "defined",
    name = "Dispater",
    glyph = 38,
    colour_id = "MAGENTA",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_TALL_TILE",
        "M_GENDER_NEUTRAL",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_DAMNATION",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_HELL_LORD",
    species_id = "MONS_DISPATER",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Dispater offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 50,
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
    average_hp_10x = 4480,
    ac = 40,
    ev = 3,
    spellbook_id = "MST_DISPATER",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Dispater, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DISPATER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
