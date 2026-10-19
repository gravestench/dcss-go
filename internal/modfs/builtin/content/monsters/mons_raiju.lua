-- raiju (MONS_RAIJU) is a DCSS monster profile with 7 hit dice and speed 10.
-- Its first melee contact is AT_BITE for 11 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_RAIJU when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_RAIJU",
    status = "defined",
    name = "raiju",
    glyph = 104,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_HOUND",
    species_id = "MONS_RAIJU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- raiju offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_ELEC",
            damage = 11,
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
    hd = 7,
    average_hp_10x = 385,
    ac = 4,
    ev = 14,
    spellbook_id = "MST_RAIJU",
    leaves_corpse = true,
    shout_id = "S_BARK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For raiju, energy costs combine with speed 10 to determine action cadence,
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
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_RAIJU",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_RAIJU",
}

register.definition(categories.MONSTERS, definition)

return definition
