-- wight (MONS_WIGHT) is a DCSS monster profile with 3 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 8 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_WIGHT",
    status = "defined",
    name = "wight",
    glyph = 122,
    colour_id = "GREEN",
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 20,
    genus_id = "MONS_WIGHT",
    species_id = "MONS_WIGHT",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 20,
    -- wight offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN",
            damage = 8,
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
    hd = 3,
    average_hp_10x = 165,
    ac = 4,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For wight, energy costs combine with speed 10 to determine action cadence,
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
        id = "TILEP_MONS_WIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place wight in depth bands beginning at 6 through 10; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 41,
            min_depth = 6,
            max_depth = 10,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_DAGGER,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 7,
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
