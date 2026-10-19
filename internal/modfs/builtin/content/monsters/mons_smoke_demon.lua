-- smoke demon (MONS_SMOKE_DEMON) is a DCSS monster profile with 7 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 8 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SMOKE_DEMON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SMOKE_DEMON",
    status = "defined",
    name = "smoke demon",
    glyph = 51,
    colour_id = "LIGHTGREY",
    flags = {
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_SMOKE_DEMON",
    species_id = "MONS_SMOKE_DEMON",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 60,
    -- smoke demon offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 8,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 7,
    average_hp_10x = 385,
    ac = 5,
    ev = 9,
    spellbook_id = "MST_SMOKE_DEMON",
    shout_id = "S_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For smoke demon, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_SMOKE_DEMON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
