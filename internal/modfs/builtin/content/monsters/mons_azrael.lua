-- Azrael (MONS_AZRAEL) is a DCSS monster profile with 11 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 17 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_AZRAEL when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_AZRAEL",
    status = "defined",
    name = "Azrael",
    glyph = 82,
    colour_id = "LIGHTRED",
    flags = {
        "M_UNIQUE",
        "M_SPEAKS",
        "M_MALE",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_DAMNATION",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_EFREET",
    species_id = "MONS_EFREET",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 40,
    -- Azrael offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 17,
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
    hd = 11,
    average_hp_10x = 880,
    ac = 10,
    ev = 5,
    spellbook_id = spellbooks.MST_AZRAEL,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Azrael, energy costs combine with speed 10 to determine action cadence,
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_AZRAEL",
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
                    id = item_ids.WPN_SCIMITAR,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 4,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.FLAMING,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
