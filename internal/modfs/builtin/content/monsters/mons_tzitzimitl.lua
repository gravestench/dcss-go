-- Tzitzimitl (MONS_TZITZIMITL) is a DCSS monster profile with 22 hit dice and
-- speed 10.
-- Its first melee contact is AT_ENGULF for 25 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_TZITZIMITL when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TZITZIMITL",
    status = "defined",
    name = "Tzitzimitl",
    glyph = 49,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_TZITZIMITL",
    species_id = "MONS_TZITZIMITL",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Tzitzimitl offers AT_ENGULF as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_ENGULF",
            flavour_id = "AF_DRAIN_SPEED",
            damage = 25,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN",
            damage = 25,
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
    hd = 22,
    average_hp_10x = 1050,
    ac = 12,
    ev = 16,
    spellbook_id = spellbooks.MST_TZITZIMITL,
    shout_id = "S_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Tzitzimitl, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_TZITZIMITL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
