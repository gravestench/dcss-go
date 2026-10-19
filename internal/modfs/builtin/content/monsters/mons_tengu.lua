-- tengu (MONS_TENGU) is a DCSS monster profile with 5 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 10 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TENGU",
    status = "defined",
    name = "tengu",
    glyph = 81,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_TENGU",
    species_id = "MONS_TENGU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- tengu offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_PECK",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 5,
    average_hp_10x = 225,
    ac = 2,
    ev = 12,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For tengu, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 9,
        swim = 9,
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
        id = "TILEP_MONS_TENGU",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TENGU",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
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
