-- Pikel (MONS_PIKEL) is a DCSS monster profile with 6 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 9 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_PIKEL",
    status = "defined",
    name = "Pikel",
    glyph = 75,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_UNIQUE",
        "M_MALE",
    },
    xp_modifier = 32,
    genus_id = "MONS_KOBOLD",
    species_id = "MONS_KOBOLD",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- Pikel offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 9,
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
    hd = 6,
    average_hp_10x = 390,
    ac = 4,
    ev = 12,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Pikel, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_PIKEL",
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
                    id = item_ids.WPN_WHIP,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 2,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.FLAMING,
                    weight = 2,
                },
                {
                    id = brands.FREEZING,
                    weight = 2,
                },
                {
                    id = brands.ELECTROCUTION,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
