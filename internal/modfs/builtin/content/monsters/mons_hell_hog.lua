-- hell hog (MONS_HELL_HOG) is a DCSS monster profile with 11 hit dice and
-- speed 14.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_HELL_HOG when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_HELL_HOG",
    status = "defined",
    name = "hell hog",
    glyph = 104,
    colour_id = "LIGHTRED",
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_HOG",
    species_id = "MONS_HELL_HOG",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 40,
    -- hell hog offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
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
    hd = 11,
    average_hp_10x = 595,
    ac = 2,
    ev = 9,
    spellbook_id = spellbooks.MST_HELL_HOG,
    leaves_corpse = true,
    shout_id = "S_SQUEAL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For hell hog, energy costs combine with speed 14 to determine action
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
        id = "TILEP_MONS_HELL_HOG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HELL_HOG",
}

register.definition(categories.MONSTERS, definition)

return definition
