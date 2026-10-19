-- hound (MONS_HOUND) is a DCSS monster profile with 3 hit dice and speed 15.
-- Its first melee contact is AT_BITE for 6 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_HOUND",
    status = "defined",
    name = "hound",
    glyph = 104,
    colour_id = "YELLOW",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_HOUND",
    species_id = "MONS_HOUND",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- hound offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 6,
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
    hd = 3,
    average_hp_10x = 165,
    ac = 2,
    ev = 13,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_BARK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For hound, energy costs combine with speed 15 to determine action cadence,
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_HOUND",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HOUND",
    -- Spawn rows place hound in depth bands beginning at 4 through 7; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 21,
            min_depth = 4,
            max_depth = 7,
            rarity = 1000,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
