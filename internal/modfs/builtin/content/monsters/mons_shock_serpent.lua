-- shock serpent (MONS_SHOCK_SERPENT) is a DCSS monster profile with 10 hit
-- dice and speed 15.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SHOCK_SERPENT when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SHOCK_SERPENT",
    status = "defined",
    name = "shock serpent",
    glyph = 83,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_COLD_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_SHOCK_SERPENT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- shock serpent offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_ELEC",
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
    hd = 10,
    average_hp_10x = 550,
    ac = 2,
    ev = 15,
    spellbook_id = "MST_SHOCK_SERPENT",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For shock serpent, energy costs combine with speed 15 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_SHOCK_SERPENT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SHOCK_SERPENT",
}

register.definition(categories.MONSTERS, definition)

return definition
