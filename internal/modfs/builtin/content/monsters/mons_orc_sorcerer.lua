-- orc sorcerer (MONS_ORC_SORCERER) is a DCSS monster profile with 9 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 7 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ORC_SORCERER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_ORC_SORCERER",
    status = "defined",
    name = "orc sorcerer",
    glyph = 111,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_WARM_BLOOD",
    },
    xp_modifier = 12,
    genus_id = "MONS_ORC",
    species_id = "MONS_ORC",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- orc sorcerer offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
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
    hd = 9,
    average_hp_10x = 315,
    ac = 5,
    ev = 12,
    spellbook_id = "MST_ORC_SORCERER",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For orc sorcerer, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_ORC_SORCERER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place orc sorcerer in depth bands beginning at 21 through 27;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 108,
            min_depth = 21,
            max_depth = 27,
            rarity = 25,
            curve = curves.PEAK,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_DAGGER,
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
