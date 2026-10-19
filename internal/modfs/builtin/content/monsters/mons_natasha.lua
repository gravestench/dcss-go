-- Natasha (MONS_NATASHA) is a DCSS monster profile with 3 hit dice and speed
-- 10.
-- Its first melee contact is AT_CLAW for 10 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_NATASHA when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_NATASHA",
    status = "defined",
    name = "Natasha",
    glyph = 104,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_UNIQUE",
        "M_FEMALE",
    },
    xp_modifier = 10,
    genus_id = "MONS_FELID",
    species_id = "MONS_FELID",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- Natasha offers AT_CLAW as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 10,
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
    average_hp_10x = 150,
    ac = 2,
    ev = 12,
    spellbook_id = spellbooks.MST_NATASHA,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Natasha, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 8,
        swim = 8,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_NATASHA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
