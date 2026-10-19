-- quokka (MONS_QUOKKA) is a DCSS monster profile with 1 hit dice and speed
-- 12.
-- Its first melee contact is AT_BITE for 5 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_QUOKKA",
    status = "defined",
    name = "quokka",
    glyph = 114,
    colour_id = "WHITE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_QUOKKA",
    species_id = "MONS_QUOKKA",
    holiness = {
        "MH_NATURAL",
    },
    -- quokka offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 1,
    average_hp_10x = 55,
    ac = 2,
    ev = 13,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For quokka, energy costs combine with speed 12 to determine action cadence,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_QUOKKA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_QUOKKA",
    -- Spawn rows place quokka in depth bands beginning at 1 through 3; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 11,
            min_depth = 1,
            max_depth = 3,
            rarity = 500,
            curve = curves.FLAT,
        },

        {
            source_order = 14,
            min_depth = 4,
            max_depth = 5,
            rarity = 500,
            curve = curves.FALL,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
