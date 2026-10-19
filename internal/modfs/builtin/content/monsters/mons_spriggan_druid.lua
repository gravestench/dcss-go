-- spriggan druid (MONS_SPRIGGAN_DRUID) is a DCSS monster profile with 11 hit
-- dice and speed 10.
-- Its first melee contact is AT_HIT for 18 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SPRIGGAN_DRUID when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_SPRIGGAN_DRUID",
    status = "defined",
    name = "spriggan druid",
    glyph = 105,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
    },
    xp_modifier = 10,
    genus_id = "MONS_SPRIGGAN",
    species_id = "MONS_SPRIGGAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- spriggan druid offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    average_hp_10x = 440,
    ac = 1,
    ev = 18,
    spellbook_id = "MST_SPRIGGAN_DRUID",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For spriggan druid, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_SPRIGGAN_DRUID",
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
                    id = item_ids.WPN_QUARTERSTAFF,
                    weight = 1,
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
