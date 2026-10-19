-- dream sheep (MONS_DREAM_SHEEP) is a DCSS monster profile with 9 hit dice
-- and speed 10.
-- Its first melee contact is AT_BITE for 13 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_DREAM_SHEEP when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DREAM_SHEEP",
    status = "defined",
    name = "dream sheep",
    glyph = 89,
    colour_id = "CYAN",
    flags = {
        "M_WARM_BLOOD",
        "M_HERD",
    },
    xp_modifier = 10,
    genus_id = "MONS_DREAM_SHEEP",
    species_id = "MONS_DREAM_SHEEP",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 30,
    -- dream sheep offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 13,
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
    hd = 9,
    average_hp_10x = 220,
    ac = 2,
    ev = 10,
    spellbook_id = "MST_DREAM_SHEEP",
    leaves_corpse = true,
    shout_id = "S_BLEAT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For dream sheep, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_DREAM_SHEEP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DREAM_SHEEP",
}

register.definition(categories.MONSTERS, definition)

return definition
