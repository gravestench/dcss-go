-- vault guard (MONS_VAULT_GUARD) is a DCSS monster profile with 13 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 20 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_VAULT_GUARD",
    status = "defined",
    name = "vault guard",
    glyph = 112,
    colour_id = "CYAN",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- vault guard offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 13,
    average_hp_10x = 715,
    ac = 1,
    ev = 13,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For vault guard, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_VAULT_GUARD",
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
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_BARDICHE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 1,
                },
            },
            plus = {
                odds = 4,
                min = 1,
                max = 3,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
