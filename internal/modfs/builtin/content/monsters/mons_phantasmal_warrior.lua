-- phantasmal warrior (MONS_PHANTASMAL_WARRIOR) is a DCSS monster profile with
-- 9 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 39 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_PHANTASMAL_WARRIOR when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_PHANTASMAL_WARRIOR",
    status = "defined",
    name = "phantasmal warrior",
    glyph = 87,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_PHANTASMAL_WARRIOR",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    -- phantasmal warrior offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_VULN",
            damage = 39,
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
    hd = 9,
    average_hp_10x = 495,
    ac = 12,
    ev = 10,
    spellbook_id = spellbooks.MST_PHANTASMAL_WARRIOR,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For phantasmal warrior, energy costs combine with speed 10 to determine
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
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_PHANTASMAL_WARRIOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place phantasmal warrior in depth bands beginning at 23 through
    -- 31; they do not mutate existing actors.
    population = {
        {
            min_depth = 23,
            max_depth = 31,
            rarity = 89,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
