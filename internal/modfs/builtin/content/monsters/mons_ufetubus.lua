-- ufetubus (MONS_UFETUBUS) is a DCSS monster profile with 1 hit dice and
-- speed 15.
-- Its first melee contact is AT_HIT for 5 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_UFETUBUS",
    status = "defined",
    name = "ufetubus",
    glyph = 53,
    colour_id = "LIGHTCYAN",
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 28,
    genus_id = "MONS_UFETUBUS",
    species_id = "MONS_UFETUBUS",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 10,
    -- ufetubus offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
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
    },
    hd = 1,
    average_hp_10x = 70,
    ac = 2,
    ev = 15,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For ufetubus, energy costs combine with speed 15 to determine action
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
        id = "TILEP_MONS_UFETUBUS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place ufetubus in depth bands beginning at 4 through 7; they do
    -- not mutate existing actors.
    population = {
        {
            min_depth = 4,
            max_depth = 7,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
