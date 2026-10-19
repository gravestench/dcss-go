-- lava snake (MONS_LAVA_SNAKE) is a DCSS monster profile with 3 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 7 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_LAVA_SNAKE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_LAVA_SNAKE",
    status = "defined",
    name = "lava snake",
    glyph = 83,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 17,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_LAVA_SNAKE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- lava snake offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_FIRE",
            damage = 7,
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
    hd = 3,
    average_hp_10x = 165,
    ac = 2,
    ev = 17,
    spellbook_id = "MST_LAVA_SNAKE",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAVA",
    speed = 10,
    -- For lava snake, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_LAVA_SNAKE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_LAVA_SNAKE",
}

register.definition(categories.MONSTERS, definition)

return definition
