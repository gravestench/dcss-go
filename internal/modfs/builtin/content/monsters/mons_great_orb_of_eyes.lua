-- great orb of eyes (MONS_GREAT_ORB_OF_EYES) is a DCSS monster profile with
-- 12 hit dice and speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_GREAT_ORB_OF_EYES when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_GREAT_ORB_OF_EYES",
    status = "defined",
    name = "great orb of eyes",
    glyph = 71,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_SEE_INVIS",
        "M_FLIES",
        "M_NO_SKELETON",
    },
    xp_modifier = 13,
    genus_id = "MONS_FLOATING_EYE",
    species_id = "MONS_GREAT_ORB_OF_EYES",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- great orb of eyes offers AT_BITE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
    hd = 12,
    average_hp_10x = 660,
    ac = 10,
    ev = 3,
    spellbook_id = "MST_GREAT_ORB_OF_EYES",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For great orb of eyes, energy costs combine with speed 10 to determine
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_ORB",
    tile = {
        id = "TILEP_MONS_GREAT_ORB_OF_EYES",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place great orb of eyes in depth bands beginning at 17 through
    -- 24; they do not mutate existing actors.
    population = {
        {
            source_order = 92,
            min_depth = 17,
            max_depth = 24,
            rarity = 102,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
