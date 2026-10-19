-- tengu conjurer (MONS_TENGU_CONJURER) is a DCSS monster profile with 7 hit
-- dice and speed 10.
-- Its first melee contact is AT_HIT for 10 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_TENGU_CONJURER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TENGU_CONJURER",
    status = "defined",
    name = "tengu conjurer",
    glyph = 81,
    colour_id = "BLUE",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 13,
    genus_id = "MONS_TENGU",
    species_id = "MONS_TENGU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- tengu conjurer offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_PECK",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 7,
    average_hp_10x = 315,
    ac = 2,
    ev = 17,
    spellbook_id = spellbooks.MST_TENGU_CONJURER,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For tengu conjurer, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 9,
        swim = 9,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_TENGU_CONJURER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place tengu conjurer in depth bands beginning at 13 through 19;
    -- they do not mutate existing actors.
    population = {
        {
            min_depth = 13,
            max_depth = 19,
            rarity = 205,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
