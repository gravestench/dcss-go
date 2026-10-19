-- flayed ghost (MONS_FLAYED_GHOST) is a DCSS monster profile with 11 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_FLAYED_GHOST when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_FLAYED_GHOST",
    status = "defined",
    name = "flayed ghost",
    glyph = 87,
    colour_id = "RED",
    flags = {
        "M_INSUBSTANTIAL",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_PHANTOM",
    species_id = "MONS_FLAYED_GHOST",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    -- flayed ghost offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
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
    hd = 11,
    average_hp_10x = 605,
    ev = 14,
    spellbook_id = "MST_FLAYED_GHOST",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For flayed ghost, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_FLAYED_GHOST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place flayed ghost in depth bands beginning at 18 through 28;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 101,
            min_depth = 18,
            max_depth = 28,
            rarity = 180,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
