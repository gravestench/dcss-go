-- glowing orange brain (MONS_GLOWING_ORANGE_BRAIN) is a DCSS monster profile
-- with 10 hit dice and speed 10.
-- It has no direct first melee contact; special actions and spell choices are
-- resolved elsewhere.
-- The AI consults MST_GLOWING_ORANGE_BRAIN when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_GLOWING_ORANGE_BRAIN",
    status = "defined",
    name = "glowing orange brain",
    glyph = 71,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_FLIES",
        "M_NO_SKELETON",
    },
    xp_modifier = 13,
    genus_id = "MONS_GLOWING_ORANGE_BRAIN",
    species_id = "MONS_GLOWING_ORANGE_BRAIN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- AT_NONE leaves the first attack slot empty; it is not a melee contact.
    attacks = {
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 10,
    average_hp_10x = 550,
    ac = 2,
    ev = 4,
    spellbook_id = "MST_GLOWING_ORANGE_BRAIN",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For glowing orange brain, energy costs combine with speed 10 to determine
    -- action cadence, not an unconditional action each turn.
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
    shape_id = "MON_SHAPE_ORB",
    tile = {
        id = "TILEP_MONS_GLOWING_ORANGE_BRAIN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place glowing orange brain in depth bands beginning at 18 through
    -- 24; they do not mutate existing actors.
    population = {
        {
            source_order = 100,
            min_depth = 18,
            max_depth = 24,
            rarity = 52,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
