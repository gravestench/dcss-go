-- death knight (MONS_DEATH_KNIGHT) is a DCSS monster profile with 10 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 28 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_DEATH_KNIGHT when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DEATH_KNIGHT",
    status = "defined",
    name = "death knight",
    glyph = 112,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_SPEAKS",
    },
    xp_modifier = 12,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- death knight offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 28,
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
    hd = 10,
    average_hp_10x = 800,
    ac = 2,
    ev = 12,
    spellbook_id = spellbooks.MST_DEATH_KNIGHT,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For death knight, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_DEATH_KNIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place death knight in depth bands beginning at 13 through 21;
    -- they do not mutate existing actors.
    population = {
        {
            min_depth = 13,
            max_depth = 21,
            rarity = 192,
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
                    weight = 5,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 15,
                },
            },
            plus = {
                odds = 2,
                min = 1,
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
