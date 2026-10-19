-- two-headed ogre (MONS_TWO_HEADED_OGRE) is a DCSS monster profile with 10
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 24 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_TWO_HEADED_OGRE",
    status = "defined",
    name = "two-headed ogre",
    glyph = 79,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_TWO_WEAPONS",
        "M_SPEAKS",
    },
    xp_modifier = 15,
    genus_id = "MONS_OGRE",
    species_id = "MONS_TWO_HEADED_OGRE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- two-headed ogre offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    ac = 3,
    ev = 6,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT2",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For two-headed ogre, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_TWO_HEADED_OGRE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TWO_HEADED_OGRE",
    -- Spawn rows place two-headed ogre in depth bands beginning at 8 through 14;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 50,
            min_depth = 8,
            max_depth = 14,
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
                    id = item_ids.WPN_GIANT_CLUB,
                    weight = 60,
                },
                {
                    id = item_ids.WPN_GIANT_SPIKED_CLUB,
                    weight = 30,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
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
