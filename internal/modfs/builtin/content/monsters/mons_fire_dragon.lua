-- fire dragon (MONS_FIRE_DRAGON) is a DCSS monster profile with 12 hit dice
-- and speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_FIRE_DRAGON_BREATH when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_FIRE_DRAGON",
    status = "defined",
    name = "fire dragon",
    glyph = 68,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_FIRE_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- fire dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 13,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 13,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 12,
    average_hp_10x = 900,
    ac = 10,
    ev = 8,
    spellbook_id = spellbooks.MST_FIRE_DRAGON_BREATH,
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For fire dragon, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_FIRE_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FIRE_DRAGON",
    -- Spawn rows place fire dragon in depth bands beginning at 14 through 27; they
    -- do not mutate existing actors.
    population = {
        {
            min_depth = 14,
            max_depth = 27,
            rarity = 192,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
