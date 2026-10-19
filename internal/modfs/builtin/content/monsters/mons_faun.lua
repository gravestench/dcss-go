-- faun (MONS_FAUN) is a DCSS monster profile with 10 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 23 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_FAUN when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_FAUN",
    status = "defined",
    name = "faun",
    glyph = 99,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 8,
    genus_id = "MONS_FAUN",
    species_id = "MONS_FAUN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- faun has AT_HIT in its first attack slot; current melee rules read that slot.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 23,
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
    average_hp_10x = 500,
    ac = 2,
    ev = 10,
    spellbook_id = "MST_FAUN",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For faun, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_MONS_FAUN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FAUN",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_CLUB,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_QUARTERSTAFF,
                    weight = 1,
                },
            },
            plus = {
                odds = 0,
                min = 0,
                max = 0,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_SLING,
                    weight = 1,
                },
            },
            plus = {
                odds = 0,
                min = 0,
                max = 0,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
