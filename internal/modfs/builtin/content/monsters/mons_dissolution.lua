-- Dissolution (MONS_DISSOLUTION) is a DCSS monster profile with 16 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 50 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_DISSOLUTION when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DISSOLUTION",
    status = "defined",
    name = "Dissolution",
    glyph = 74,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_ACID_SPLASH",
        "M_BURROWS",
        "M_SPEAKS",
        "M_FAST_REGEN",
        "M_GENDER_NEUTRAL",
        "M_EAT_DOORS",
        "M_WEB_IMMUNE",
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ACID",
            level = 3,
        },
    },
    xp_modifier = 60,
    genus_id = "MONS_JELLY",
    species_id = "MONS_JELLY",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- Dissolution offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ACID",
            damage = 50,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ACID",
            damage = 30,
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
    hd = 16,
    average_hp_10x = 1760,
    ac = 10,
    ev = 1,
    spellbook_id = spellbooks.MST_DISSOLUTION,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Dissolution, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_BLOB",
    tile = {
        id = "TILEP_MONS_DISSOLUTION",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
