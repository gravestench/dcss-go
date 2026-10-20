-- yaktaur captain (MONS_YAKTAUR_CAPTAIN) is a DCSS monster profile with 14
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_YAKTAUR_CAPTAIN",
    status = "defined",
    name = "yaktaur captain",
    glyph = 99,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_ARCHER",
        "M_SPEAKS",
    },
    xp_modifier = 9,
    genus_id = "MONS_YAKTAUR",
    species_id = "MONS_YAKTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- yaktaur captain offers AT_HIT as its first contact; later slots are tried by
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
    hd = 14,
    average_hp_10x = 770,
    ac = 5,
    ev = 5,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For yaktaur captain, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_CENTAUR",
    tile = {
        id = "TILEP_MONS_YAKTAUR_CAPTAIN",
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
                    id = item_ids.WPN_ARBALEST,
                    weight = 19,
                },
                {
                    id = item_ids.WPN_HAND_CROSSBOW,
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
