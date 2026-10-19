-- doom hound (MONS_DOOM_HOUND) is a DCSS monster profile with 20 hit dice and
-- speed 13.
-- Its first melee contact is AT_BITE for 45 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_DOOM_HOUND when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DOOM_HOUND",
    status = "defined",
    name = "doom hound",
    glyph = 104,
    colour_id = "GREEN",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
    },
    xp_modifier = 10,
    genus_id = "MONS_HOUND",
    species_id = "MONS_DOOM_HOUND",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 20,
    -- doom hound offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 45,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    hd = 20,
    average_hp_10x = 1100,
    ac = 6,
    ev = 13,
    spellbook_id = spellbooks.MST_DOOM_HOUND,
    leaves_corpse = true,
    shout_id = "S_BARK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For doom hound, energy costs combine with speed 13 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_DOOM_HOUND",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DOOM_HOUND",
}

register.definition(categories.MONSTERS, definition)

return definition
