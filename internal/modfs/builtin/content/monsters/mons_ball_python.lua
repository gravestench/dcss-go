-- ball python (MONS_BALL_PYTHON) is a DCSS monster profile with 1 hit dice
-- and speed 12.
-- Its first melee contact is AT_BITE for 3 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BALL_PYTHON",
    status = "defined",
    name = "ball python",
    glyph = 83,
    colour_id = "GREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_BALL_PYTHON",
    holiness = {
        "MH_NATURAL",
    },
    -- ball python offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 3,
        },
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 1,
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
    hd = 1,
    average_hp_10x = 35,
    ev = 11,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 12,
    -- For ball python, energy costs combine with speed 12 to determine action
    -- cadence, not an unconditional action each turn.
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_BALL_PYTHON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BALL_PYTHON",
    -- Spawn rows place ball python in depth bands beginning at 1 through 4; they
    -- do not mutate existing actors.
    population = {
        {
            min_depth = 1,
            max_depth = 4,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
