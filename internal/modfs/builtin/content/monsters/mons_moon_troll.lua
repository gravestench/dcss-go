-- moon troll (MONS_MOON_TROLL) is a DCSS monster profile with 18 hit dice and
-- speed 12.
-- Its first melee contact is AT_BITE for 35 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_MOON_TROLL when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MOON_TROLL",
    status = "defined",
    name = "moon troll",
    glyph = 84,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FAST_REGEN",
        "M_SEE_INVIS",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
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
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_TROLL",
    species_id = "MONS_MOON_TROLL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    -- moon troll offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 35,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 18,
    average_hp_10x = 990,
    ac = 20,
    ev = 4,
    spellbook_id = "MST_MOON_TROLL",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For moon troll, energy costs combine with speed 12 to determine action
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
        id = "TILEP_MONS_MOON_TROLL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
