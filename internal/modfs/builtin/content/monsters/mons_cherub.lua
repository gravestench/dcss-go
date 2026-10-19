-- cherub (MONS_CHERUB) is a DCSS monster profile with 9 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 15 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_BATTLECRY when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_CHERUB",
    status = "defined",
    name = "cherub",
    glyph = 65,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_FIGHTER",
        "M_ARCHER",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_ANGEL",
    species_id = "MONS_CHERUB",
    holiness = {
        "MH_HOLY",
    },
    willpower = 100,
    -- cherub offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_CHERUB",
            flavour_id = "AF_PLAIN",
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
    },
    hd = 9,
    average_hp_10x = 765,
    ac = 10,
    ev = 20,
    spellbook_id = spellbooks.MST_BATTLECRY,
    shout_id = "S_CHERUB",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For cherub, energy costs combine with speed 10 to determine action cadence,
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
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_CHERUB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        -- Brand list: crawl-ref/source/mon-gear.cc
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 4,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.FLAMING,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
        -- Source: crawl-ref/source/mon-gear.cc
        -- Spec: crawl-ref/source/mon-gear.cc
        -- Weapon list: crawl-ref/source/mon-gear.cc
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_SLING,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_SHORTBOW,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_LONGBOW,
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
