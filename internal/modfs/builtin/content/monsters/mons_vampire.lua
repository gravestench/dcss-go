-- vampire (MONS_VAMPIRE) is a DCSS monster profile with 6 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 15 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_VAMPIRE when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_VAMPIRE",
    status = "defined",
    name = "vampire",
    glyph = 86,
    colour_id = "RED",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_VAMPIRE",
    species_id = "MONS_VAMPIRE",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    -- vampire offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_VAMPIRIC",
            damage = 15,
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
    hd = 6,
    average_hp_10x = 330,
    ac = 10,
    ev = 10,
    spellbook_id = spellbooks.MST_VAMPIRE,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For vampire, energy costs combine with speed 10 to determine action cadence,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_VAMPIRE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place vampire in depth bands beginning at 9 through 14; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 55,
            min_depth = 9,
            max_depth = 14,
            rarity = 200,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
