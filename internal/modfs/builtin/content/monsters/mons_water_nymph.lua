-- water nymph (MONS_WATER_NYMPH) is a DCSS monster profile with 10 hit dice
-- and speed 10.
-- Its first melee contact is AT_TOUCH for 12 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_WATER_NYMPH when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WATER_NYMPH",
    status = "defined",
    name = "water nymph",
    glyph = 109,
    colour_id = "MAGENTA",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_WATER_NYMPH",
    species_id = "MONS_WATER_NYMPH",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- water nymph offers AT_TOUCH as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_DROWN",
            damage = 12,
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
    average_hp_10x = 400,
    ac = 2,
    ev = 13,
    spellbook_id = "MST_WATER_NYMPH",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For water nymph, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_WATER_NYMPH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WATER_NYMPH",
}

register.definition(categories.MONSTERS, definition)

return definition
