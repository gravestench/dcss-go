-- war gargoyle (MONS_WAR_GARGOYLE) is a DCSS monster profile with 13 hit dice
-- and speed 14.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SPLINTER_BREATH when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_WAR_GARGOYLE",
    status = "defined",
    name = "war gargoyle",
    glyph = 57,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_FIGHTER",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_WAR_GARGOYLE",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 100,
    -- war gargoyle offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
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
    hd = 13,
    average_hp_10x = 520,
    ac = 22,
    ev = 4,
    spellbook_id = "MST_SPLINTER_BREATH",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For war gargoyle, energy costs combine with speed 14 to determine action
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
        id = "TILEP_MONS_WAR_GARGOYLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place war gargoyle in depth bands beginning at 24 through 27;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 122,
            min_depth = 24,
            max_depth = 27,
            rarity = 25,
            curve = curves.FLAT,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        -- Brand list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_LAJATANG,
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
            good_chance = 4,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
