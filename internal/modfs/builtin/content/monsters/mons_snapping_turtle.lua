-- snapping turtle (MONS_SNAPPING_TURTLE) is a DCSS monster profile with 10
-- hit dice and speed 8.
-- Its first melee contact is AT_BITE for 30 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SNAPPING_TURTLE",
    status = "defined",
    name = "snapping turtle",
    glyph = 116,
    colour_id = "GREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_SNAPPING_TURTLE",
    species_id = "MONS_SNAPPING_TURTLE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- snapping turtle offers AT_BITE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_REACH",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 10,
    average_hp_10x = 600,
    ac = 16,
    ev = 5,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 8,
    -- For snapping turtle, energy costs combine with speed 8 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 8,
        missile = 8,
        spell = 8,
        special = 8,
        item = 8,
        pickup_percent = 80,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_SNAPPING_TURTLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SNAPPING_TURTLE",
}

register.definition(categories.MONSTERS, definition)

return definition
