-- ghost moth (MONS_GHOST_MOTH) is a DCSS monster profile with 13 hit dice and
-- speed 12.
-- Its first melee contact is AT_HIT for 24 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_DRAIN_GAZE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_GHOST_MOTH",
    status = "defined",
    name = "ghost moth",
    glyph = 121,
    colour_id = "MAGENTA",
    flags = {
        "M_NO_SKELETON",
        "M_INVIS",
        "M_FLIES",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 16,
    genus_id = "MONS_MOTH",
    species_id = "MONS_GHOST_MOTH",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- ghost moth offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN_STAT",
            damage = 24,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN_STAT",
            damage = 18,
        },
        {
            type_id = "AT_STING",
            flavour_id = "AF_DRAIN_STAT",
            damage = 18,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 13,
    average_hp_10x = 715,
    ac = 8,
    ev = 10,
    spellbook_id = spellbooks.MST_DRAIN_GAZE,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For ghost moth, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_GHOST_MOTH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GHOST_MOTH",
}

register.definition(categories.MONSTERS, definition)

return definition
