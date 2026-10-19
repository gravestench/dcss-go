-- bat (MONS_BAT) is a DCSS monster profile with 1 hit dice and speed 30.
-- Its first melee contact is AT_HIT for 1 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_BAT",
    status = "defined",
    name = "bat",
    glyph = 98,
    colour_id = "LIGHTGREY",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_WARM_BLOOD",
        "M_BATTY",
        "M_FLIES",
    },
    xp_modifier = 4,
    genus_id = "MONS_BAT",
    species_id = "MONS_BAT",
    holiness = {
        "MH_NATURAL",
    },
    -- bat has AT_HIT in its first attack slot; current melee rules read that slot.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 1,
    average_hp_10x = 35,
    ac = 1,
    ev = 14,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 30,
    -- For bat, energy costs combine with speed 30 to determine action cadence, not
    -- an unconditional action each turn.
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
    shape_id = "MON_SHAPE_BAT",
    tile = {
        id = "TILEP_MONS_BAT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BAT",
    -- Spawn rows place bat in depth bands beginning at 1 through 3; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 1,
            min_depth = 1,
            max_depth = 3,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
