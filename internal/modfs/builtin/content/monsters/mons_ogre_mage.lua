-- ogre mage (MONS_OGRE_MAGE) is a DCSS monster profile with 10 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 16 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_OGRE_MAGE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_OGRE_MAGE",
    status = "defined",
    name = "ogre mage",
    glyph = 79,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 16,
    genus_id = "MONS_OGRE",
    species_id = "MONS_OGRE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- ogre mage offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
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
    average_hp_10x = 550,
    ac = 1,
    ev = 7,
    spellbook_id = spellbooks.MST_OGRE_MAGE,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For ogre mage, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 15,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_OGRE_MAGE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place ogre mage in depth bands beginning at 15 through 25; they
    -- do not mutate existing actors.
    population = {
        {
            min_depth = 15,
            max_depth = 25,
            rarity = 315,
            curve = curves.FALL,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_CLUB,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 6,
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
