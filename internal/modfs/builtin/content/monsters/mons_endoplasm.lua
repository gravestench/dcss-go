-- endoplasm (MONS_ENDOPLASM) is a DCSS monster profile with 1 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 3 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ENDOPLASM when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ENDOPLASM",
    status = "defined",
    name = "endoplasm",
    glyph = 74,
    colour_id = "LIGHTGREY",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
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
    xp_modifier = 10,
    genus_id = "MONS_JELLY",
    species_id = "MONS_ENDOPLASM",
    holiness = {
        "MH_NATURAL",
    },
    -- endoplasm offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
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
    average_hp_10x = 60,
    ac = 1,
    ev = 3,
    spellbook_id = spellbooks.MST_ENDOPLASM,
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For endoplasm, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_BLOB",
    tile = {
        id = "TILEP_MONS_ENDOPLASM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
