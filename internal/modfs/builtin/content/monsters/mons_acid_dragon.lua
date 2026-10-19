-- acid dragon (MONS_ACID_DRAGON) is a DCSS monster profile with 5 hit dice
-- and speed 10.
-- Its first melee contact is AT_BITE for 15 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_ACID_DRAGON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_ACID_DRAGON",
    status = "defined",
    name = "acid dragon",
    glyph = 68,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ACID",
            level = 1,
        },
    },
    xp_modifier = 16,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_ACID_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- acid dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 6,
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
    hd = 5,
    average_hp_10x = 275,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_ACID_DRAGON",
    leaves_corpse = true,
    shout_id = "S_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For acid dragon, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_ACID_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ACID_DRAGON",
    -- Spawn rows place acid dragon in depth bands beginning at 8 through 14; they
    -- do not mutate existing actors.
    population = {
        {
            source_order = 49,
            min_depth = 8,
            max_depth = 14,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
