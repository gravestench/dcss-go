-- death drake (MONS_DEATH_DRAKE) is a DCSS monster profile with 9 hit dice
-- and speed 13.
-- Its first melee contact is AT_BITE for 12 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_DEATH_DRAKE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DEATH_DRAKE",
    status = "defined",
    name = "death drake",
    glyph = 107,
    colour_id = "LIGHTGREY",
    flags = {
        "M_COLD_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_MIASMA",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_DRAKE",
    species_id = "MONS_DEATH_DRAKE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- death drake offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 12,
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
    hd = 9,
    average_hp_10x = 765,
    ac = 6,
    ev = 14,
    spellbook_id = spellbooks.MST_DEATH_DRAKE,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For death drake, energy costs combine with speed 13 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_DEATH_DRAKE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DEATH_DRAKE",
}

register.definition(categories.MONSTERS, definition)

return definition
