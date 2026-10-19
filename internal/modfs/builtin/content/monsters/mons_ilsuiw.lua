-- Ilsuiw (MONS_ILSUIW) is a DCSS monster profile with 16 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 10 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ILSUIW when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_ILSUIW",
    status = "defined",
    name = "Ilsuiw",
    glyph = 109,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FEMALE",
    },
    xp_modifier = 10,
    genus_id = "MONS_MERFOLK",
    species_id = "MONS_MERFOLK",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    -- Ilsuiw offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
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
    hd = 16,
    average_hp_10x = 1520,
    ac = 5,
    ev = 18,
    spellbook_id = "MST_ILSUIW",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For Ilsuiw, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ILSUIW",
        variation_id = "TVARY_WATER",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        -- Brand list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = -1,
                max = 6,
                rolls = 2,
            },
            brands = {
                {
                    id = brands.FREEZING,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
