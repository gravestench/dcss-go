-- meliai (MONS_MELIAI) is a DCSS monster profile with 7 hit dice and speed
-- 20.
-- Its first melee contact is AT_HIT for 14 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_MELIAI when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_MELIAI",
    status = "defined",
    name = "meliai",
    glyph = 121,
    colour_id = "GREEN",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_KILLER_BEE",
    species_id = "MONS_MELIAI",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- meliai offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON",
            damage = 12,
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
    hd = 7,
    average_hp_10x = 245,
    ac = 2,
    ev = 14,
    spellbook_id = spellbooks.MST_MELIAI,
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 20,
    -- For meliai, energy costs combine with speed 20 to determine action cadence,
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_MELIAI",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_MELIAI",
    -- Spawn rows place meliai in depth bands beginning at 13 through 20; they do
    -- not mutate existing actors.
    population = {
        {
            min_depth = 13,
            max_depth = 20,
            rarity = 150,
            curve = curves.SEMI,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 12,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
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
