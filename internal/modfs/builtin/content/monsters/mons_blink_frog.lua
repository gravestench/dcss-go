-- blink frog (MONS_BLINK_FROG) is a DCSS monster profile with 6 hit dice and
-- speed 14.
-- Its first melee contact is AT_HIT for 20 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_BLINKER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BLINK_FROG",
    status = "defined",
    name = "blink frog",
    glyph = 70,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_FROG",
    species_id = "MONS_BLINK_FROG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- blink frog offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_BLINK",
            damage = 20,
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
    average_hp_10x = 330,
    ev = 16,
    spellbook_id = spellbooks.MST_BLINKER,
    leaves_corpse = true,
    shout_id = "S_CROAK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 14,
    -- For blink frog, energy costs combine with speed 14 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_BLINK_FROG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BLINK_FROG",
}

register.definition(categories.MONSTERS, definition)

return definition
