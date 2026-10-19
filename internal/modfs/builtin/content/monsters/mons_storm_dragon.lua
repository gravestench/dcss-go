-- storm dragon (MONS_STORM_DRAGON) is a DCSS monster profile with 14 hit dice
-- and speed 12.
-- Its first melee contact is AT_BITE for 25 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_STORM_DRAGON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_STORM_DRAGON",
    status = "defined",
    name = "storm dragon",
    glyph = 68,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_STORM_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- storm dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 14,
    average_hp_10x = 1050,
    ac = 13,
    ev = 10,
    spellbook_id = spellbooks.MST_STORM_DRAGON,
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For storm dragon, energy costs combine with speed 12 to determine action
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_STORM_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_STORM_DRAGON",
    -- Spawn rows place storm dragon in depth bands beginning at 23 through 27;
    -- they do not mutate existing actors.
    population = {
        {
            min_depth = 23,
            max_depth = 27,
            rarity = 89,
            curve = curves.RISE,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
