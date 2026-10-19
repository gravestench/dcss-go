-- steam dragon (MONS_STEAM_DRAGON) is a DCSS monster profile with 4 hit dice
-- and speed 10.
-- Its first melee contact is AT_BITE for 12 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_STEAM_DRAGON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_STEAM_DRAGON",
    status = "defined",
    name = "steam dragon",
    glyph = 68,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_STEAM",
            level = 1,
        },
    },
    xp_modifier = 29,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_STEAM_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- steam dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 12,
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
    hd = 4,
    average_hp_10x = 300,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_STEAM_DRAGON",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For steam dragon, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_STEAM_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_STEAM_DRAGON",
    -- Spawn rows place steam dragon in depth bands beginning at 6 through 10; they
    -- do not mutate existing actors.
    population = {
        {
            source_order = 42,
            min_depth = 6,
            max_depth = 10,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
