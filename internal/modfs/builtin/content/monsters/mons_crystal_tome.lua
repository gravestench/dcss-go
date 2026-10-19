-- walking crystal tome (MONS_CRYSTAL_TOME) is a DCSS monster profile with 15
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 40 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_WALKING_TOME when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")
local spells = require("ids.spells")

local definition = {
    id = "MONS_CRYSTAL_TOME",
    status = "defined",
    name = "walking crystal tome",
    glyph = 59,
    colour_id = "CYAN",
    xp_modifier = 25,
    genus_id = "MONS_WALKING_TOME",
    species_id = "MONS_EARTHEN_TOME",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- walking crystal tome offers AT_HIT as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 40,
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
    hd = 15,
    average_hp_10x = 1000,
    ac = 15,
    ev = 5,
    spellbook_id = spellbooks.MST_WALKING_TOME,
    -- The conjured actor carries this spell after it leaves the tome.
    living_spell_id = spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
    shout_id = "S_RUSTLE",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For walking crystal tome, energy costs combine with speed 10 to determine
    -- action cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 20,
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
        id = "TILEP_MONS_CRYSTAL_TOME",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
