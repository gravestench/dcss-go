-- sphinx (MONS_SPHINX) is a DCSS monster profile with 16 hit dice and speed
-- 11.
-- Its first melee contact is AT_HIT for 25 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SPHINX when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SPHINX",
    status = "defined",
    name = "sphinx",
    glyph = 72,
    colour_id = "LIGHTGREY",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 12,
    genus_id = "MONS_SPHINX",
    species_id = "MONS_SPHINX",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- sphinx offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 12,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 12,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 16,
    average_hp_10x = 880,
    ac = 5,
    ev = 5,
    spellbook_id = spellbooks.MST_SPHINX,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 11,
    -- For sphinx, energy costs combine with speed 11 to determine action cadence,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SPHINX",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SPHINX",
    -- Spawn rows place sphinx in depth bands beginning at 19 through 27; they do
    -- not mutate existing actors.
    population = {
        {
            min_depth = 19,
            max_depth = 27,
            rarity = 89,
            curve = curves.RISE,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
