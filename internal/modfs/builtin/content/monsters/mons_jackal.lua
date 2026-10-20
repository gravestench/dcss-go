-- jackal (MONS_JACKAL) is a DCSS monster profile with 1 hit dice and speed
-- 14.
-- Its first melee contact is AT_BITE for 3 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local monsters = require("ids.monsters")

local definition = {
    id = "MONS_JACKAL",
    -- Ordinary jackals arrive in packs of one-to-four followers.
    -- The same saved follower links and cell checks serve unique bands.
    band = {
        min = 1,
        max = 4,
        slots = {
            {
                monsters.MONS_JACKAL,
            },
        },
    },
    status = "defined",
    name = "jackal",
    glyph = 104,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_HOUND",
    species_id = "MONS_JACKAL",
    holiness = {
        "MH_NATURAL",
    },
    -- jackal offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 3,
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
    hd = 1,
    average_hp_10x = 55,
    ac = 2,
    ev = 12,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_BARK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For jackal, energy costs combine with speed 14 to determine action cadence,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_JACKAL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_JACKAL",
}

register.definition(categories.MONSTERS, definition)

return definition
