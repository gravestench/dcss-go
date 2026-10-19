-- Psyche (MONS_PSYCHE) is a DCSS monster profile with 5 hit dice and speed
-- 13.
-- Its first melee contact is AT_HIT for 7 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_PSYCHE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_PSYCHE",
    status = "defined",
    name = "Psyche",
    glyph = 64,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FEMALE",
    },
    xp_modifier = 20,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- Psyche offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 7,
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
    hd = 5,
    average_hp_10x = 400,
    ev = 12,
    spellbook_id = "MST_PSYCHE",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For Psyche, energy costs combine with speed 13 to determine action cadence,
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_PSYCHE",
        variation_id = "TVARY_NONE",
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
                    id = item_ids.WPN_DAGGER,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 4,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.CHAOS,
                    weight = 3,
                },
                {
                    id = brands.DISTORTION,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
