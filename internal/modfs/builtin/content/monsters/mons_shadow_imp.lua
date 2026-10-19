-- shadow imp (MONS_SHADOW_IMP) is a DCSS monster profile with 2 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 6 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SHADOW_IMP when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_SHADOW_IMP",
    status = "defined",
    name = "shadow imp",
    glyph = 53,
    colour_id = "MAGENTA",
    flags = {
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_SHADOW_IMP",
    species_id = "MONS_SHADOW_IMP",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 10,
    -- shadow imp offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 2,
    average_hp_10x = 110,
    ac = 3,
    ev = 11,
    spellbook_id = "MST_SHADOW_IMP",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For shadow imp, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_SHADOW_IMP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place shadow imp in depth bands beginning at 5 through 8; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 34,
            min_depth = 5,
            max_depth = 8,
            rarity = 300,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
