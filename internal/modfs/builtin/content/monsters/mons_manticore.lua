-- manticore (MONS_MANTICORE) is a DCSS monster profile with 9 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 26 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_MANTICORE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_MANTICORE",
    status = "defined",
    name = "manticore",
    glyph = 72,
    colour_id = "RED",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_MANTICORE",
    species_id = "MONS_MANTICORE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- manticore offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 26,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 9,
    average_hp_10x = 495,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_MANTICORE",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For manticore, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_MANTICORE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_MANTICORE",
    -- Spawn rows place manticore in depth bands beginning at 11 through 21; they
    -- do not mutate existing actors.
    population = {
        {
            source_order = 61,
            min_depth = 11,
            max_depth = 21,
            rarity = 520,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
