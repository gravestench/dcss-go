-- boggart (MONS_BOGGART) is a DCSS monster profile with 4 hit dice and speed
-- 12.
-- Its first melee contact is AT_HIT for 5 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_BOGGART when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_BOGGART",
    status = "defined",
    name = "boggart",
    glyph = 103,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
    },
    xp_modifier = 14,
    genus_id = "MONS_BOGGART",
    species_id = "MONS_BOGGART",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- boggart offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 5,
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
    hd = 4,
    average_hp_10x = 200,
    ev = 12,
    spellbook_id = "MST_BOGGART",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For boggart, energy costs combine with speed 12 to determine action cadence,
    -- not an unconditional action each turn.
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_BOGGART",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place boggart in depth bands beginning at 14 through 22; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 82,
            min_depth = 14,
            max_depth = 22,
            rarity = 115,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
