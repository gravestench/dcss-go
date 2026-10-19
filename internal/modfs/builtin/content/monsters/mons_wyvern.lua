-- wyvern (MONS_WYVERN) is a DCSS monster profile with 5 hit dice and speed
-- 15.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_WYVERN",
    status = "defined",
    name = "wyvern",
    glyph = 108,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 15,
    genus_id = "MONS_WYVERN",
    species_id = "MONS_WYVERN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- wyvern offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 5,
    average_hp_10x = 275,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For wyvern, energy costs combine with speed 15 to determine action cadence,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_WYVERN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WYVERN",
    -- Spawn rows place wyvern in depth bands beginning at 7 through 11; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 47,
            min_depth = 7,
            max_depth = 11,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
