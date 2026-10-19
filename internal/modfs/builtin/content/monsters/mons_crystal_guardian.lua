-- crystal guardian (MONS_CRYSTAL_GUARDIAN) is a DCSS monster profile with 16
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 35 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_CRYSTAL_GUARDIAN when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_CRYSTAL_GUARDIAN",
    status = "defined",
    name = "crystal guardian",
    glyph = 57,
    colour_id = "GREEN",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_CRYSTAL_GUARDIAN",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- crystal guardian offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 35,
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
    hd = 16,
    average_hp_10x = 640,
    ac = 22,
    spellbook_id = "MST_CRYSTAL_GUARDIAN",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For crystal guardian, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_CRYSTAL_GUARDIAN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place crystal guardian in depth bands beginning at 25 through 27;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 123,
            min_depth = 25,
            max_depth = 27,
            rarity = 12,
            curve = curves.RISE,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
