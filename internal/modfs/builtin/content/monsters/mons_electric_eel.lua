-- electric eel (MONS_ELECTRIC_EEL) is a DCSS monster profile with 3 hit dice
-- and speed 10.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- The AI consults MST_ZAPPER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ELECTRIC_EEL",
    status = "defined",
    name = "electric eel",
    glyph = 83,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_NO_GEN_DERIVED",
        "M_COLD_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 19,
    genus_id = "MONS_ELECTRIC_EEL",
    species_id = "MONS_ELECTRIC_EEL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
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
    hd = 3,
    average_hp_10x = 165,
    ac = 1,
    ev = 15,
    spellbook_id = spellbooks.MST_ZAPPER,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_WATER",
    speed = 10,
    -- For electric eel, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_ELECTRIC_EEL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ELECTRIC_EEL",
}

register.definition(categories.MONSTERS, definition)

return definition
