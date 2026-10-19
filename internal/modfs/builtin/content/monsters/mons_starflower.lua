-- starflower (MONS_STARFLOWER) is a DCSS monster profile with 16 hit dice and
-- speed 10.
-- Its first melee contact is AT_TENTACLE_SLAP for 22 base damage; combat
-- policy applies defenses and status effects.
-- The AI consults MST_STARFLOWER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_STARFLOWER",
    status = "defined",
    name = "starflower",
    glyph = 80,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_STATIONARY",
    },
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
        {
            id = "MR_RES_ACID",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_PLANT",
    species_id = "MONS_STARFLOWER",
    holiness = {
        "MH_PLANT",
    },
    willpower = 100,
    -- starflower offers AT_TENTACLE_SLAP as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_RIFT",
            damage = 22,
        },
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_REACH",
            damage = 17,
        },
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_DISTORT",
            damage = 13,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 16,
    average_hp_10x = 900,
    ac = 16,
    spellbook_id = spellbooks.MST_STARFLOWER,
    shout_id = "S_GURGLE",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For starflower, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_PLANT",
    tile = {
        id = "TILEP_MONS_STARFLOWER",
        variation_id = "TVARY_CYCLE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
