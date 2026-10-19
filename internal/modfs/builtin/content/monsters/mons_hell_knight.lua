-- hell knight (MONS_HELL_KNIGHT) is a DCSS monster profile with 10 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 26 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_HELL_KNIGHT when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_HELL_KNIGHT",
    status = "defined",
    name = "hell knight",
    glyph = 112,
    colour_id = "RED",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- hell knight offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 26,
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
    average_hp_10x = 650,
    ev = 10,
    spellbook_id = spellbooks.MST_HELL_KNIGHT,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For hell knight, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_HELL_KNIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place hell knight in depth bands beginning at 23 through 29; they
    -- do not mutate existing actors.
    population = {
        {
            min_depth = 23,
            max_depth = 29,
            rarity = 25,
            curve = curves.PEAK,
        },
    },
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
                    id = item_ids.WPN_HALBERD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 5,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.FLAMING,
                    weight = 13,
                },
                {
                    id = brands.DRAINING,
                    weight = 4,
                },
                {
                    id = brands.VORPAL,
                    weight = 4,
                },
                {
                    id = brands.DISTORTION,
                    weight = 2,
                },
                {
                    id = brands.PAIN,
                    weight = 2,
                },
                {
                    id = sentinels.NO_FORCED_BRAND,
                    weight = 20,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
