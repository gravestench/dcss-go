-- deathcap (MONS_DEATHCAP) is a DCSS monster profile with 13 hit dice and
-- speed 10.
-- Its first melee contact is AT_SPORE for 33 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_DEATHCAP when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEATHCAP",
    status = "defined",
    name = "deathcap",
    glyph = 102,
    colour_id = "LIGHTMAGENTA",
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_FUNGUS",
    species_id = "MONS_WANDERING_MUSHROOM",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    -- deathcap offers AT_SPORE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_SPORE",
            flavour_id = "AF_CONFUSE",
            damage = 33,
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
    hd = 13,
    average_hp_10x = 520,
    ac = 5,
    spellbook_id = "MST_DEATHCAP",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For deathcap, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_FUNGUS",
    tile = {
        id = "TILEP_MONS_DEATHCAP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
