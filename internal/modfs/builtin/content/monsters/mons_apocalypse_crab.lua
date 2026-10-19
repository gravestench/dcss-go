-- apocalypse crab (MONS_APOCALYPSE_CRAB) is a DCSS monster profile with 8 hit
-- dice and speed 10.
-- Its first melee contact is AT_BITE for 15 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_APOCALYPSE_CRAB when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_APOCALYPSE_CRAB",
    status = "defined",
    name = "apocalypse crab",
    glyph = 116,
    colour_id = "WHITE",
    flags = {
        "M_NO_SKELETON",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_CRAB",
    species_id = "MONS_APOCALYPSE_CRAB",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 60,
    -- apocalypse crab offers AT_BITE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_CHAOTIC",
            damage = 15,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_CHAOTIC",
            damage = 15,
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
    hd = 8,
    average_hp_10x = 520,
    ac = 11,
    ev = 6,
    spellbook_id = spellbooks.MST_APOCALYPSE_CRAB,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For apocalypse crab, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_APOCALYPSE_CRAB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_APOCALYPSE_CRAB",
}

register.definition(categories.MONSTERS, definition)

return definition
