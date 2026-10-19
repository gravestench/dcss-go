-- player ghost (MONS_PLAYER_GHOST) is a DCSS monster profile with 4 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 5 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_GHOST when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_PLAYER_GHOST",
    status = "defined",
    name = "player ghost",
    glyph = 87,
    colour_id = "WHITE",
    flags = {
        "M_FIGHTER",
        "M_SPEAKS",
        "M_INSUBSTANTIAL",
        "M_NO_POLY_TO",
        "M_FLIES",
        "M_GHOST_DEMON",
    },
    xp_modifier = 15,
    genus_id = "MONS_PHANTOM",
    species_id = "MONS_PLAYER_GHOST",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = -5,
    -- player ghost offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 5,
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
    hd = 4,
    average_hp_10x = 140,
    ac = 1,
    ev = 2,
    spellbook_id = spellbooks.MST_GHOST,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For player ghost, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_PLAYER_GHOST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
