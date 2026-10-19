-- quasit (MONS_QUASIT) is a DCSS monster profile with 3 hit dice and speed
-- 13.
-- Its first melee contact is AT_BITE for 3 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_QUASIT",
    status = "defined",
    name = "quasit",
    glyph = 53,
    colour_id = "LIGHTGREY",
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_QUASIT",
    species_id = "MONS_QUASIT",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 10,
    -- quasit offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN_DEX",
            damage = 3,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_DRAIN_DEX",
            damage = 2,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_DRAIN_DEX",
            damage = 2,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 3,
    average_hp_10x = 150,
    ac = 5,
    ev = 17,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For quasit, energy costs combine with speed 13 to determine action cadence,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_QUASIT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
