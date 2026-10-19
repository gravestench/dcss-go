-- alligator snapping turtle (MONS_ALLIGATOR_SNAPPING_TURTLE) is a DCSS
-- monster profile with 16 hit dice and speed 8.
-- Its first melee contact is AT_BITE for 50 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ALLIGATOR_SNAPPING_TURTLE",
    status = "defined",
    name = "alligator snapping turtle",
    glyph = 116,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_SNAPPING_TURTLE",
    species_id = "MONS_ALLIGATOR_SNAPPING_TURTLE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- alligator snapping turtle offers AT_BITE as its first contact; later slots
    -- are tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_REACH",
            damage = 50,
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
    hd = 16,
    average_hp_10x = 1440,
    ac = 19,
    ev = 1,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 8,
    -- For alligator snapping turtle, energy costs combine with speed 8 to
    -- determine action cadence, not an unconditional action each turn.
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_ALLIGATOR_SNAPPING_TURTLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ALLIGATOR_SNAPPING_TURTLE",
}

register.definition(categories.MONSTERS, definition)

return definition
