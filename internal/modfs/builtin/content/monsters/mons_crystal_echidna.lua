-- crystal echidna (MONS_CRYSTAL_ECHIDNA) is a DCSS monster profile with 12
-- hit dice and speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_CRYSTAL_ECHIDNA when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_CRYSTAL_ECHIDNA",
    status = "defined",
    name = "crystal echidna",
    glyph = 114,
    colour_id = "GREEN",
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_CRYSTAL_ECHIDNA",
    species_id = "MONS_CRYSTAL_ECHIDNA",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- crystal echidna offers AT_BITE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 12,
    average_hp_10x = 640,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_CRYSTAL_ECHIDNA",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For crystal echidna, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_CRYSTAL_ECHIDNA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
