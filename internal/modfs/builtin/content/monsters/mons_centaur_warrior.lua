-- centaur warrior (MONS_CENTAUR_WARRIOR) is a DCSS monster profile with 10
-- hit dice and speed 15.
-- Its first melee contact is AT_HIT for 16 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_CENTAUR_WARRIOR",
    status = "defined",
    name = "centaur warrior",
    glyph = 99,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_ARCHER",
        "M_SPEAKS",
    },
    xp_modifier = 12,
    genus_id = "MONS_CENTAUR",
    species_id = "MONS_CENTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- centaur warrior offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_KICK",
            flavour_id = "AF_PLAIN",
            damage = 5,
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
    ac = 4,
    ev = 8,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For centaur warrior, energy costs combine with speed 15 to determine action
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
        id = "TILEP_MONS_CENTAUR_WARRIOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place centaur warrior in depth bands beginning at 13 through 17;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 72,
            min_depth = 13,
            max_depth = 17,
            rarity = 925,
            curve = curves.FLAT,
        },

        {
            source_order = 73,
            min_depth = 18,
            max_depth = 23,
            rarity = 925,
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
                    id = item_ids.WPN_SHORTBOW,
                    weight = 2,
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
