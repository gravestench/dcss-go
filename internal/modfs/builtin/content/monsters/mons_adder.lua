-- adder (MONS_ADDER) is a DCSS monster profile with 2 hit dice and speed 13.
-- Its first melee contact is AT_BITE for 4 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ADDER",
    status = "defined",
    name = "adder",
    glyph = 83,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_ADDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- adder offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_POISON",
            damage = 4,
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
    hd = 2,
    average_hp_10x = 110,
    ac = 1,
    ev = 15,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 13,
    -- For adder, energy costs combine with speed 13 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_ADDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ADDER",
    -- Spawn rows place adder in depth bands beginning at 2 through 6; they do not
    -- mutate existing actors.
    population = {
        {
            min_depth = 2,
            max_depth = 6,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
