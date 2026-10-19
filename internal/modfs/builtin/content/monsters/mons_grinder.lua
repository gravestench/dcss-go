-- Grinder (MONS_GRINDER) is a DCSS monster profile with 6 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 11 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_GRINDER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_GRINDER",
    status = "defined",
    name = "Grinder",
    glyph = 53,
    colour_id = "BLUE",
    flags = {
        "M_UNIQUE",
        "M_SPEAKS",
        "M_NO_HT_WAND",
        "M_FEMALE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_SHADOW_IMP",
    species_id = "MONS_SHADOW_IMP",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 20,
    -- Grinder offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PAIN",
            damage = 11,
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
    average_hp_10x = 390,
    ac = 3,
    ev = 11,
    spellbook_id = spellbooks.MST_GRINDER,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Grinder, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_GRINDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
