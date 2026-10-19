-- wendigo (MONS_WENDIGO) is a DCSS monster profile with 15 hit dice and speed
-- 10.
-- Its first melee contact is AT_CLAW for 30 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_WENDIGO when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WENDIGO",
    status = "defined",
    name = "wendigo",
    glyph = 82,
    colour_id = "BLUE",
    flags = {
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_WENDIGO",
    species_id = "MONS_WENDIGO",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 140,
    -- wendigo offers AT_CLAW as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_COLD",
            damage = 30,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_VAMPIRIC",
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
    hd = 15,
    average_hp_10x = 880,
    ac = 4,
    ev = 20,
    spellbook_id = "MST_WENDIGO",
    shout_id = "S_HOWL",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For wendigo, energy costs combine with speed 10 to determine action cadence,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_WENDIGO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
