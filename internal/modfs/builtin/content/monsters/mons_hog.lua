-- hog (MONS_HOG) is a DCSS monster profile with 6 hit dice and speed 13.
-- Its first melee contact is AT_BITE for 14 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_HOG",
    status = "defined",
    name = "hog",
    glyph = 104,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_HOG",
    species_id = "MONS_HOG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- hog has AT_BITE in its first attack slot; current melee rules read that slot.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 14,
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
    hd = 6,
    average_hp_10x = 330,
    ac = 2,
    ev = 9,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SQUEAL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For hog, energy costs combine with speed 13 to determine action cadence, not
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_HOG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HOG",
}

register.definition(categories.MONSTERS, definition)

return definition
