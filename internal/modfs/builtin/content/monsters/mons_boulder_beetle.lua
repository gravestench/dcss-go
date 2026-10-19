-- boulder beetle (MONS_BOULDER_BEETLE) is a DCSS monster profile with 12 hit
-- dice and speed 10.
-- Its first melee contact is AT_BITE for 32 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_BOULDER_BEETLE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BOULDER_BEETLE",
    status = "defined",
    name = "boulder beetle",
    glyph = 66,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_BOULDER_BEETLE",
    species_id = "MONS_BOULDER_BEETLE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- boulder beetle offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 32,
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
    average_hp_10x = 765,
    ac = 20,
    ev = 2,
    spellbook_id = spellbooks.MST_BOULDER_BEETLE,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For boulder beetle, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_INSECT",
    tile = {
        id = "TILEP_MONS_BOULDER_BEETLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BOULDER_BEETLE",
    -- Spawn rows place boulder beetle in depth bands beginning at 11 through 23;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 66,
            min_depth = 11,
            max_depth = 23,
            rarity = 540,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
