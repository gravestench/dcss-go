-- curse skull (MONS_CURSE_SKULL) is a DCSS monster profile with 13 hit dice
-- and speed 15.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- The AI consults MST_CURSE_SKULL when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_CURSE_SKULL",
    status = "defined",
    name = "curse skull",
    glyph = 122,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 20,
    genus_id = "MONS_CURSE_SKULL",
    species_id = "MONS_CURSE_SKULL",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 5000,
    -- AT_NONE leaves the first attack slot empty; it is not a melee contact.
    attacks = {
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 13,
    average_hp_10x = 520,
    ac = 35,
    ev = 3,
    spellbook_id = "MST_CURSE_SKULL",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For curse skull, energy costs combine with speed 15 to determine action
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_CURSE_SKULL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
