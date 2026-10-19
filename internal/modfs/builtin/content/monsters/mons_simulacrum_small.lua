-- small simulacrum (MONS_SIMULACRUM_SMALL) is a DCSS monster profile with 2
-- hit dice and speed 7.
-- Its first melee contact is AT_HIT for 6 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SIMULACRUM_SMALL",
    status = "defined",
    name = "small simulacrum",
    glyph = 90,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_NO_REGEN",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 9,
    genus_id = "MONS_SIMULACRUM",
    species_id = "MONS_SIMULACRUM",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = -1,
    -- small simulacrum offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
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
    hd = 2,
    average_hp_10x = 110,
    ac = 10,
    ev = 4,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 7,
    -- For small simulacrum, energy costs combine with speed 7 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_SIMULACRUM_SMALL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
