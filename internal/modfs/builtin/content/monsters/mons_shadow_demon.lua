-- shadow demon (MONS_SHADOW_DEMON) is a DCSS monster profile with 10 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 21 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SHADOW_DEMON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SHADOW_DEMON",
    status = "defined",
    name = "shadow demon",
    glyph = 50,
    colour_id = "MAGENTA",
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
            level = 2,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_SHADOW_DEMON",
    species_id = "MONS_SHADOW_DEMON",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 100,
    -- shadow demon offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 21,
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
    hd = 10,
    average_hp_10x = 550,
    ac = 7,
    ev = 12,
    spellbook_id = spellbooks.MST_SHADOW_DEMON,
    shout_id = "S_CROAK",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For shadow demon, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_SHADOW_DEMON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
