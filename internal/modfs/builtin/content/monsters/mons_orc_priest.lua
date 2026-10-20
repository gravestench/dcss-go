-- orc priest (MONS_ORC_PRIEST) is a DCSS monster profile with 3 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 3 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ORC_PRIEST when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ORC_PRIEST",
    status = "defined",
    name = "orc priest",
    glyph = 111,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_ORC",
    species_id = "MONS_ORC",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- orc priest offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
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
    hd = 3,
    average_hp_10x = 150,
    ac = 1,
    ev = 10,
    spellbook_id = spellbooks.MST_ORC_PRIEST,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For orc priest, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_ORC_PRIEST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",

    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_CLUB,
                    weight = 100,
                },
                {
                    id = item_ids.WPN_DAGGER,
                    weight = 80,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 60,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 60,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 80,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 45,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 40,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 14,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 6,
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
