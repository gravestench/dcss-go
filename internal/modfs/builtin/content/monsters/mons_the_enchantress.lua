-- the Enchantress (MONS_THE_ENCHANTRESS) is a DCSS monster profile with 15
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 26 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_THE_ENCHANTRESS when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local monsters = require("ids.monsters")

local definition = {
    id = "MONS_THE_ENCHANTRESS",
    -- The Enchantress starts with three defenders and an air mage.
    -- Only the later slots draw from her mixed spriggan entourage.
    band = {
        min = 6,
        max = 11,
        slots = {
            {
                monsters.MONS_SPRIGGAN_DEFENDER,
            },
            {
                monsters.MONS_SPRIGGAN_DEFENDER,
            },
            {
                monsters.MONS_SPRIGGAN_DEFENDER,
            },
            {
                monsters.MONS_SPRIGGAN_AIR_MAGE,
            },
            {
                {
                    id = monsters.MONS_SPRIGGAN_AIR_MAGE,
                    weight = 1,
                },
                {
                    id = monsters.MONS_SPRIGGAN_BERSERKER,
                    weight = 1,
                },
                {
                    id = monsters.MONS_SPRIGGAN_RIDER,
                    weight = 1,
                },
                {
                    id = monsters.MONS_SPRIGGAN,
                    weight = 3,
                },
            },
        },
    },
    status = "defined",
    name = "the Enchantress",
    glyph = 105,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
        "M_UNIQUE",
        "M_FEMALE",
    },
    xp_modifier = 35,
    genus_id = "MONS_SPRIGGAN",
    species_id = "MONS_SPRIGGAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 160,
    -- the Enchantress offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
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
    hd = 15,
    average_hp_10x = 975,
    ac = 1,
    ev = 30,
    spellbook_id = spellbooks.MST_THE_ENCHANTRESS,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For the Enchantress, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 6,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_THE_ENCHANTRESS",
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
                    id = item_ids.WPN_LAJATANG,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_QUICK_BLADE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_RAPIER,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_FLAIL,
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
