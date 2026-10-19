-- gnoll bouda (MONS_GNOLL_BOUDA) is a DCSS monster profile with 3 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 10 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_BOUDA when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_GNOLL_BOUDA",
    status = "defined",
    name = "gnoll bouda",
    glyph = 103,
    colour_id = "WHITE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_GNOLL",
    species_id = "MONS_GNOLL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- gnoll bouda offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
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
    average_hp_10x = 195,
    ac = 2,
    ev = 9,
    spellbook_id = "MST_BOUDA",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For gnoll bouda, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_GNOLL_BOUDA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place gnoll bouda in depth bands beginning at 4 through 10; they
    -- do not mutate existing actors.
    population = {
        {
            source_order = 29,
            min_depth = 4,
            max_depth = 10,
            rarity = 200,
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
                    id = item_ids.WPN_CLUB,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_WHIP,
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
