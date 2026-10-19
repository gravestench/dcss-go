-- gargoyle (MONS_GARGOYLE) is a DCSS monster profile with 6 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 20 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_GARGOYLE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_GARGOYLE",
    status = "defined",
    name = "gargoyle",
    glyph = 57,
    colour_id = "LIGHTGREY",
    flags = {
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 26,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_GARGOYLE",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 40,
    -- gargoyle offers AT_HIT as its first contact; later slots are tried by the
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
    hd = 6,
    average_hp_10x = 270,
    ac = 18,
    ev = 6,
    spellbook_id = "MST_GARGOYLE",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For gargoyle, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID_WINGED_TAILED",
    tile = {
        id = "TILEP_MONS_GARGOYLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place gargoyle in depth bands beginning at 10 through 14; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 58,
            min_depth = 10,
            max_depth = 14,
            rarity = 350,
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
                    id = item_ids.WPN_MACE,
                    weight = 15,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 2,
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
