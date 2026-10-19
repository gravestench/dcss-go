-- white imp (MONS_WHITE_IMP) is a DCSS monster profile with 2 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 4 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_WHITE_IMP when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_WHITE_IMP",
    status = "defined",
    name = "white imp",
    glyph = 53,
    colour_id = "WHITE",
    flags = {
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_WHITE_IMP",
    species_id = "MONS_WHITE_IMP",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 10,
    -- white imp offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_COLD",
            damage = 4,
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
    hd = 2,
    average_hp_10x = 110,
    ac = 4,
    ev = 10,
    spellbook_id = spellbooks.MST_WHITE_IMP,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For white imp, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_WHITE_IMP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place white imp in depth bands beginning at 5 through 8; they do
    -- not mutate existing actors.
    population = {
        {
            min_depth = 5,
            max_depth = 8,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
