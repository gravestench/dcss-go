-- shard shrike (MONS_SHARD_SHRIKE) is a DCSS monster profile with 21 hit dice
-- and speed 30.
-- Its first melee contact is AT_CLAW for 21 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SHARD_SHRIKE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SHARD_SHRIKE",
    status = "defined",
    name = "shard shrike",
    glyph = 98,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_BATTY",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_SHARD_SHRIKE",
    species_id = "MONS_SHARD_SHRIKE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- shard shrike offers AT_CLAW as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_COLD",
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
    hd = 21,
    average_hp_10x = 1050,
    ac = 2,
    ev = 18,
    spellbook_id = spellbooks.MST_SHARD_SHRIKE,
    leaves_corpse = true,
    shout_id = "S_SCREECH",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 30,
    -- For shard shrike, energy costs combine with speed 30 to determine action
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_BIRD",
    tile = {
        id = "TILEP_MONS_SHARD_SHRIKE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SHARD_SHRIKE",
}

register.definition(categories.MONSTERS, definition)

return definition
