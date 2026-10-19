-- ancient champion (MONS_ANCIENT_CHAMPION) is a DCSS monster profile with 14
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 32 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ANCIENT_CHAMPION when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_ANCIENT_CHAMPION",
    status = "defined",
    name = "ancient champion",
    glyph = 122,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_FIGHTER",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 24,
    genus_id = "MONS_ANCIENT_CHAMPION",
    species_id = "MONS_ANCIENT_CHAMPION",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 120,
    -- ancient champion offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 32,
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
    hd = 14,
    average_hp_10x = 700,
    ac = 15,
    ev = 10,
    spellbook_id = "MST_ANCIENT_CHAMPION",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For ancient champion, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_ANCIENT_CHAMPION",
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
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 3,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.DRAINING,
                    weight = 13,
                },
                {
                    id = brands.VORPAL,
                    weight = 7,
                },
                {
                    id = brands.FREEZING,
                    weight = 4,
                },
                {
                    id = brands.FLAMING,
                    weight = 4,
                },
                {
                    id = brands.PAIN,
                    weight = 2,
                },
                {
                    id = sentinels.NO_FORCED_BRAND,
                    weight = 15,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
