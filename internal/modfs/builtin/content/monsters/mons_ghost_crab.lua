-- ghost crab (MONS_GHOST_CRAB) is a DCSS monster profile with 9 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_GHOST_CRAB when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GHOST_CRAB",
    status = "defined",
    name = "ghost crab",
    glyph = 116,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_SKELETON",
    },
    xp_modifier = 25,
    genus_id = "MONS_CRAB",
    species_id = "MONS_GHOST_CRAB",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    -- ghost crab offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_DRAIN",
            damage = 15,
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
    hd = 9,
    average_hp_10x = 585,
    ac = 9,
    ev = 6,
    spellbook_id = "MST_GHOST_CRAB",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For ghost crab, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_GHOST_CRAB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GHOST_CRAB",
}

register.definition(categories.MONSTERS, definition)

return definition
