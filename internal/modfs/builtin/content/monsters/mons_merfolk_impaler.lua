-- merfolk impaler (MONS_MERFOLK_IMPALER) is a DCSS monster profile with 12
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 22 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_MERFOLK_IMPALER",
    status = "defined",
    name = "merfolk impaler",
    glyph = 109,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 13,
    genus_id = "MONS_MERFOLK",
    species_id = "MONS_MERFOLK",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- merfolk impaler offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 22,
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
    hd = 12,
    average_hp_10x = 780,
    ev = 18,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For merfolk impaler, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 6,
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
        id = "TILEP_MONS_MERFOLK_IMPALER",
        variation_id = "TVARY_WATER",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 3,
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
