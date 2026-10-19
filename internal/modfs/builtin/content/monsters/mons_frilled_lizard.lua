-- frilled lizard (MONS_FRILLED_LIZARD) is a DCSS monster profile with 1 hit
-- dice and speed 10.
-- Its first melee contact is AT_BITE for 3 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_FRILLED_LIZARD",
    status = "defined",
    name = "frilled lizard",
    glyph = 108,
    colour_id = "GREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT_LIZARD",
    species_id = "MONS_FRILLED_LIZARD",
    holiness = {
        "MH_NATURAL",
    },
    -- frilled lizard offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 3,
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
    average_hp_10x = 20,
    ev = 15,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For frilled lizard, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_FRILLED_LIZARD",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FRILLED_LIZARD",
    -- Spawn rows place frilled lizard in depth bands beginning at 1 through 3;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 3,
            min_depth = 1,
            max_depth = 3,
            rarity = 640,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
