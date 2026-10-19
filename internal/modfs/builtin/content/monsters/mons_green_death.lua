-- green death (MONS_GREEN_DEATH) is a DCSS monster profile with 13 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 32 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_GREEN_DEATH when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GREEN_DEATH",
    status = "defined",
    name = "green death",
    glyph = 50,
    colour_id = "GREEN",
    flags = {
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_GREEN_DEATH",
    species_id = "MONS_GREEN_DEATH",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 160,
    -- green death offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 32,
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
    average_hp_10x = 715,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_GREEN_DEATH",
    shout_id = "S_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For green death, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_GREEN_DEATH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
