-- demonspawn warmonger (MONS_DEMONSPAWN_WARMONGER) is a DCSS monster profile
-- with 15 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 40 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_DEMONSPAWN_WARMONGER when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local sentinels = require("constants.monster_gear_sentinels")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DEMONSPAWN_WARMONGER",
    status = "defined",
    name = "demonspawn warmonger",
    glyph = 54,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FIGHTER",
    },
    xp_modifier = 10,
    genus_id = "MONS_DEMONSPAWN",
    species_id = "MONS_DEMONSPAWN",
    holiness = {
        "MH_NATURAL",
        "MH_DEMONIC",
    },
    willpower = 60,
    -- demonspawn warmonger offers AT_HIT as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    },
    hd = 15,
    average_hp_10x = 1250,
    ac = 3,
    ev = 12,
    spellbook_id = spellbooks.MST_DEMONSPAWN_WARMONGER,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For demonspawn warmonger, energy costs combine with speed 10 to determine
    -- action cadence, not an unconditional action each turn.
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
        id = "TILEP_MONS_DEMONSPAWN_WARMONGER",
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
                    id = item_ids.WPN_DEMON_BLADE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_DOUBLE_SWORD,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_BARDICHE,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_LAJATANG,
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
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        -- Brand list: crawl-ref/source/mon-gear.cc
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_LONGBOW,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_ARBALEST,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_TRIPLE_CROSSBOW,
                    weight = 1,
                },
                {
                    id = sentinels.NO_WEAPON,
                    weight = 40,
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
