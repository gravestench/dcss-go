-- Asterion (MONS_ASTERION) is a DCSS monster profile with 15 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 35 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ASTERION when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_ASTERION",
    status = "defined",
    name = "Asterion",
    glyph = 72,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
        "M_UNIQUE",
        "M_MALE",
    },
    xp_modifier = 15,
    genus_id = "MONS_MINOTAUR",
    species_id = "MONS_MINOTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- Asterion offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 35,
        },
        {
            type_id = "AT_GORE",
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
    },
    hd = 15,
    average_hp_10x = 1275,
    ac = 4,
    ev = 4,
    spellbook_id = "MST_ASTERION",
    leaves_corpse = true,
    shout_id = "S_BELLOW",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Asterion, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ASTERION",
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
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DEMON_BLADE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
            },
            plus = {
                odds = 0,
                min = 0,
                max = 0,
                rolls = 0,
            },
            brands = {
            },
            good_chance = 1,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
