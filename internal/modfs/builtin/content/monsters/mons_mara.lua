-- Mara (MONS_MARA) is a DCSS monster profile with 18 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_MARA when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_MARA",
    status = "defined",
    name = "Mara",
    glyph = 82,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_UNIQUE",
        "M_MALE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
    },
    xp_modifier = 35,
    genus_id = "MONS_RAKSHASA",
    species_id = "MONS_RAKSHASA",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 140,
    -- Mara has AT_HIT in its first attack slot; current melee rules read that slot.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    hd = 18,
    average_hp_10x = 1440,
    ac = 10,
    ev = 14,
    spellbook_id = "MST_MARA",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Mara, energy costs combine with speed 10 to determine action cadence,
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
        id = "TILEP_MONS_MARA",
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
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DEMON_BLADE,
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
