-- wolf spider (MONS_WOLF_SPIDER) is a DCSS monster profile with 11 hit dice
-- and speed 15.
-- Its first melee contact is AT_HIT for 25 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_WOLF_SPIDER",
    status = "defined",
    name = "wolf spider",
    glyph = 115,
    colour_id = "WHITE",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 4,
    genus_id = "MONS_SPIDER",
    species_id = "MONS_WOLF_SPIDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- wolf spider offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_POISON",
            damage = 15,
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
    hd = 11,
    average_hp_10x = 550,
    ac = 3,
    ev = 10,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SKITTER",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For wolf spider, energy costs combine with speed 15 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_WOLF_SPIDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WOLF_SPIDER",
    -- Spawn rows place wolf spider in depth bands beginning at 15 through 25; they
    -- do not mutate existing actors.
    population = {
        {
            min_depth = 15,
            max_depth = 25,
            rarity = 275,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
