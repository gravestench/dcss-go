-- Robin (MONS_ROBIN) is a DCSS monster profile with 2 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 2 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ROBIN when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ROBIN",
    status = "defined",
    name = "Robin",
    glyph = 103,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_GENDER_NEUTRAL",
    },
    xp_modifier = 10,
    genus_id = "MONS_GOBLIN",
    species_id = "MONS_HOBGOBLIN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- Robin offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 2,
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
    hd = 2,
    average_hp_10x = 160,
    ac = 1,
    ev = 8,
    spellbook_id = spellbooks.MST_ROBIN,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Robin, energy costs combine with speed 10 to determine action cadence,
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
        id = "TILEP_MONS_ROBIN",
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
                    weight = 35,
                },
                {
                    id = item_ids.WPN_DAGGER,
                    weight = 30,
                },
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 30,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 15,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 10,
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
