-- naga mage (MONS_NAGA_MAGE) is a DCSS monster profile with 7 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 14 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_NAGA_MAGE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_NAGA_MAGE",
    status = "defined",
    name = "naga mage",
    glyph = 78,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_NAGA",
    species_id = "MONS_NAGA",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- naga mage offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 4,
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
    hd = 7,
    average_hp_10x = 385,
    ac = 6,
    ev = 10,
    spellbook_id = "MST_NAGA_MAGE",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For naga mage, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 14,
        swim = 14,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_NAGA",
    tile = {
        id = "TILEP_MONS_NAGA_MAGE",
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
                    id = item_ids.WPN_SPEAR,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_CLUB,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_FLAIL,
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
