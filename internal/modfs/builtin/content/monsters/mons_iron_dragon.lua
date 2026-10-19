-- iron dragon (MONS_IRON_DRAGON) is a DCSS monster profile with 18 hit dice
-- and speed 8.
-- Its first melee contact is AT_BITE for 25 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SPLINTER_BREATH when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_IRON_DRAGON",
    status = "defined",
    name = "iron dragon",
    glyph = 68,
    colour_id = "CYAN",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_IRON_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 160,
    -- iron dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 25,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 18,
    average_hp_10x = 1170,
    ac = 20,
    ev = 6,
    spellbook_id = spellbooks.MST_SPLINTER_BREATH,
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 8,
    -- For iron dragon, energy costs combine with speed 8 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_IRON_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_IRON_DRAGON",
    -- Spawn rows place iron dragon in depth bands beginning at 27 through 27; they
    -- do not mutate existing actors.
    population = {
        {
            source_order = 125,
            min_depth = 27,
            max_depth = 27,
            rarity = 8,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
