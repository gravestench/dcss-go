-- centaur (MONS_CENTAUR) is a DCSS monster profile with 4 hit dice and speed
-- 15.
-- Its first melee contact is AT_HIT for 7 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_CENTAUR",
    status = "defined",
    name = "centaur",
    glyph = 99,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_ARCHER",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_CENTAUR",
    species_id = "MONS_CENTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- centaur offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 7,
        },
        {
            type_id = "AT_KICK",
            flavour_id = "AF_PLAIN",
            damage = 3,
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
    hd = 4,
    average_hp_10x = 220,
    ac = 3,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For centaur, energy costs combine with speed 15 to determine action cadence,
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_CENTAUR",
    tile = {
        id = "TILEP_MONS_CENTAUR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_CENTAUR",
    -- Spawn rows place centaur in depth bands beginning at 5 through 13; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 37,
            min_depth = 5,
            max_depth = 13,
            rarity = 600,
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
                    id = item_ids.WPN_SHORTBOW,
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
