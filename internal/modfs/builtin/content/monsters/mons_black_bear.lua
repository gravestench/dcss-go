-- black bear (MONS_BLACK_BEAR) is a DCSS monster profile with 6 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 9 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_BEAR when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BLACK_BEAR",
    status = "defined",
    name = "black bear",
    glyph = 104,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 9,
    genus_id = "MONS_BEAR",
    species_id = "MONS_BLACK_BEAR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- black bear offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 9,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 6,
    average_hp_10x = 270,
    ac = 2,
    ev = 8,
    spellbook_id = spellbooks.MST_BEAR,
    leaves_corpse = true,
    shout_id = "S_GROWL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For black bear, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_BLACK_BEAR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BLACK_BEAR",
    -- Spawn rows place black bear in depth bands beginning at 4 through 8; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 28,
            min_depth = 4,
            max_depth = 8,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
