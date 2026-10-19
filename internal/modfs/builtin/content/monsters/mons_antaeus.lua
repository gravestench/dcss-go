-- Antaeus (MONS_ANTAEUS) is a DCSS monster profile with 22 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 75 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ANTAEUS when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ANTAEUS",
    status = "defined",
    name = "Antaeus",
    glyph = 67,
    colour_id = "WHITE",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_MALE",
        "M_SPEAKS",
        "M_TALL_TILE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT",
    species_id = "MONS_TITAN",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Antaeus offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_COLD",
            damage = 75,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_COLD",
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
    hd = 22,
    average_hp_10x = 6820,
    ac = 28,
    ev = 4,
    spellbook_id = spellbooks.MST_ANTAEUS,
    shout_id = "S_DEMON_TAUNT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For Antaeus, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ANTAEUS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
