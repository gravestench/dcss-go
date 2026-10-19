-- salamander (MONS_SALAMANDER) is a DCSS monster profile with 8 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 17 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_SALAMANDER",
    status = "defined",
    name = "salamander",
    glyph = 78,
    colour_id = "LIGHTRED",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_NAGA",
    species_id = "MONS_SALAMANDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- salamander offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_FIRE",
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
    hd = 8,
    average_hp_10x = 640,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS_LAVA",
    speed = 10,
    -- For salamander, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 7,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_NAGA",
    tile = {
        id = "TILEP_MONS_SALAMANDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SALAMANDER",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_SHORTBOW,
                    weight = 5,
                },
            },
            plus = {
                odds = 4,
                min = 0,
                max = 4,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
